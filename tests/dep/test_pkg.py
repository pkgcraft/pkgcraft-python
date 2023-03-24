import inspect
import itertools
import pickle
import re

import pytest

from pkgcraft.dep import Blocker, Cpv, Dep, Operator, SlotOperator, VersionWithOp
from pkgcraft.eapi import EAPIS, eapi_range
from pkgcraft.error import InvalidDep
from pkgcraft.restrict import Restrict

from ..misc import OperatorIterMap, OperatorMap


class TestBlocker:
    def test_from_str(self):
        for s in ("", "!!!", "a"):
            with pytest.raises(ValueError):
                Blocker.from_str(s)


class TestSlotOperator:
    def test_from_str(self):
        for s in ("", "=*", "*=", "~"):
            with pytest.raises(ValueError):
                SlotOperator.from_str(s)


class TestDep:
    def test_init(self):
        # no version
        a = Dep("cat/pkg")
        assert a.category == "cat"
        assert a.package == "pkg"
        assert a.blocker is None
        assert a.slot is None
        assert a.subslot is None
        assert a.slot_op is None
        assert a.use is None
        assert a.repo is None
        assert a.version is None
        assert a.revision is None
        assert a.p == "pkg"
        assert a.pf == "pkg"
        assert a.pr is None
        assert a.pv is None
        assert a.pvr is None
        assert a.cpn == "cat/pkg"
        assert a.cpv == "cat/pkg"
        assert str(a) == "cat/pkg"
        assert repr(a).startswith("<Dep 'cat/pkg' at 0x")

        # all fields -- extended EAPI default allows repo deps
        a = Dep("!!>=cat/pkg-1-r2:0/2=[a,b,c]::repo")
        assert a.category == "cat"
        assert a.package == "pkg"
        assert a.blocker == Blocker.Strong
        assert a.blocker == "!!"
        assert a.slot == "0"
        assert a.subslot == "2"
        assert a.slot_op == SlotOperator.Equal
        assert a.slot_op == "="
        assert a.use == ("a", "b", "c")
        assert a.repo == "repo"
        assert a.version == VersionWithOp(">=1-r2")
        assert a.op == Operator.GreaterOrEqual
        assert a.op == ">="
        assert a.revision == "2"
        assert a.p == "pkg-1"
        assert a.pf == "pkg-1-r2"
        assert a.pr == "r2"
        assert a.pv == "1"
        assert a.pvr == "1-r2"
        assert a.cpn == "cat/pkg"
        assert a.cpv == "cat/pkg-1-r2"
        assert str(a) == "!!>=cat/pkg-1-r2:0/2=[a,b,c]::repo"
        assert repr(a).startswith("<Dep '!!>=cat/pkg-1-r2:0/2=[a,b,c]::repo' at 0x")

        # explicitly specifying an official EAPI fails
        for eapi in ("8", EAPIS["8"]):
            with pytest.raises(InvalidDep):
                Dep("cat/pkg::repo", eapi)

        # unknown EAPI
        with pytest.raises(ValueError, match="unknown EAPI"):
            Dep("cat/pkg", "nonexistent")

        # invalid EAPI type
        with pytest.raises(TypeError):
            Dep("cat/pkg", object())

    def test_matches(self):
        a = Dep("=cat/pkg-1")
        r = Restrict(a)
        assert a.matches(r)
        assert not a.matches(~r)

    def test_valid(self, toml_data):
        attrs = []
        for attr, val in inspect.getmembers(Dep):
            if inspect.isgetsetdescriptor(val):
                attrs.append(attr)

        # converters for toml data
        converters = {
            "blocker": Blocker.from_str,
            "version": VersionWithOp,
            "slot_op": SlotOperator.from_str,
            "use": tuple,
        }

        for entry in toml_data["dep.toml"]["valid"]:
            s = entry["dep"]

            # convert toml strings into expected types
            for k in set(entry).intersection(converters):
                if val := entry.get(k):
                    entry[k] = converters[k](val)

            passing_eapis = eapi_range(entry["eapis"])
            for eapi in EAPIS.values():
                if eapi in passing_eapis:
                    a = Dep(s, eapi)
                    assert a.category == entry.get("category")
                    assert a.package == entry.get("package")
                    assert a.blocker == entry.get("blocker")
                    assert a.version == entry.get("version")
                    assert a.revision == entry.get("revision")
                    assert a.slot == entry.get("slot")
                    assert a.subslot == entry.get("subslot")
                    assert a.slot_op == entry.get("slot_op")
                    assert a.use == entry.get("use")
                    assert str(a) == s
                    assert repr(a).startswith(f"<Dep {s!r} at 0x")
                else:
                    with pytest.raises(InvalidDep, match=f"invalid dep: {re.escape(s)}"):
                        Dep(s, eapi)

    def test_invalid(self, toml_data):
        for s in toml_data["dep.toml"]["invalid"]:
            for eapi in EAPIS.values():
                with pytest.raises(InvalidDep, match=f"invalid dep: {re.escape(s)}"):
                    Dep(s, eapi)

    def test_invalid_arg_type(self):
        for obj in (object(), None):
            with pytest.raises(TypeError):
                Dep(obj)

    def test_cmp(self, toml_data):
        for s in toml_data["dep.toml"]["compares"]:
            s1, op, s2 = s.split()
            d1 = Dep(s1)
            d2 = Dep(s2)
            for op_func in OperatorIterMap[op]:
                assert op_func(d1, d2), f"failed comparison: {s}"

        for s in toml_data["version.toml"]["compares"]:
            s1, op, s2 = s.split()
            d1 = Dep(f"=cat/pkg-{s1}")
            d2 = Dep(f"=cat/pkg-{s2}")
            for op_func in OperatorIterMap[op]:
                assert op_func(d1, d2), f"failed comparison: {s}"

        # verify incompatible type comparisons
        obj = Dep("=cat/pkg-1")
        for op, op_func in OperatorMap.items():
            if op == "==":
                assert not op_func(obj, None)
            elif op == "!=":
                assert op_func(obj, None)
            else:
                with pytest.raises(TypeError):
                    op_func(obj, None)

    def test_intersects(self, toml_data):
        def parse(s):
            """Convert string to Dep falling back to Cpv."""
            try:
                return Dep(s)
            except InvalidDep:
                return Cpv(s)

        for d in toml_data["dep.toml"]["intersects"]:
            # test intersections between all pairs of distinct values
            for s1, s2 in itertools.permutations(d["vals"], 2):
                (obj1, obj2) = (parse(s1), parse(s2))

                # objects intersect themselves
                assert obj1.intersects(obj1)
                assert obj2.intersects(obj2)

                # intersect or not depending on status
                if d["status"]:
                    assert obj1.intersects(obj2)
                else:
                    assert not obj1.intersects(obj2)

        # invalid type
        with pytest.raises(TypeError):
            Dep("cat/pkg").intersects(object())

    def test_sort(self, toml_data):
        for d in toml_data["dep.toml"]["sorting"]:
            expected = [Dep(s) for s in d["sorted"]]
            ordered = sorted(reversed(expected))
            if d["equal"]:
                # equal deps aren't sorted so reversing should restore the original order
                ordered = list(reversed(ordered))
            assert ordered == expected

    def test_hash(self, toml_data):
        for d in toml_data["version.toml"]["hashing"]:
            s = {Dep(f"=cat/pkg-{x}") for x in d["versions"]}
            length = 1 if d["equal"] else len(d["versions"])
            assert len(s) == length

    def test_cached(self):
        l = [Dep.cached("cat/pkg") for _ in range(1000)]
        assert len(l) == 1000

    def test_pickle(self):
        a = Dep("=cat/pkg-1-r2:0/2=[a,b,c]")
        b = pickle.loads(pickle.dumps(a))
        assert a == b
