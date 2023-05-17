import inspect
import itertools
import pickle
import re

import pytest

from pkgcraft.dep import Blocker, Cpn, Cpv, Dep, Operator, SlotOperator, Version
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
        dep = Dep("cat/pkg")
        assert dep.category == "cat"
        assert dep.package == "pkg"
        assert dep.blocker is None
        assert dep.slot is None
        assert dep.subslot is None
        assert dep.slot_op is None
        assert dep.use is None
        assert dep.repo is None
        assert dep.version is None
        assert dep.revision is None
        assert dep.p == "pkg"
        assert dep.pf == "pkg"
        assert dep.pr is None
        assert dep.pv is None
        assert dep.pvr is None
        assert dep.cpn == "cat/pkg"
        assert dep.cpv == "cat/pkg"
        assert str(dep) == "cat/pkg"
        assert repr(dep).startswith("<Dep 'cat/pkg' at 0x")

        # all fields -- extended EAPI default allows repo deps
        dep = Dep("!!>=cat/pkg-1-r2:0/2=[a,b,c]::repo")
        assert dep.category == "cat"
        assert dep.package == "pkg"
        assert dep.blocker == Blocker.Strong
        assert dep.blocker == "!!"
        assert dep.slot == "0"
        assert dep.subslot == "2"
        assert dep.slot_op == SlotOperator.Equal
        assert dep.slot_op == "="
        assert dep.use == ("a", "b", "c")
        assert dep.repo == "repo"
        assert dep.version == Version(">=1-r2")
        assert dep.op == Operator.GreaterOrEqual
        assert dep.op == ">="
        assert dep.revision == "2"
        assert dep.p == "pkg-1"
        assert dep.pf == "pkg-1-r2"
        assert dep.pr == "r2"
        assert dep.pv == "1"
        assert dep.pvr == "1-r2"
        assert dep.cpn == "cat/pkg"
        assert dep.cpv == "cat/pkg-1-r2"
        assert str(dep) == "!!>=cat/pkg-1-r2:0/2=[a,b,c]::repo"
        assert repr(dep).startswith("<Dep '!!>=cat/pkg-1-r2:0/2=[a,b,c]::repo' at 0x")

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
        dep = Dep("=cat/pkg-1")
        r = Restrict(dep)
        assert dep.matches(r)
        assert not dep.matches(~r)

    def test_valid(self, testdata_toml):
        attrs = []
        for attr, val in inspect.getmembers(Dep):
            if inspect.isgetsetdescriptor(val):
                attrs.append(attr)

        # converters for toml data
        converters = {
            "blocker": Blocker.from_str,
            "version": Version,
            "slot_op": SlotOperator.from_str,
            "use": tuple,
        }

        for entry in testdata_toml["dep.toml"]["valid"]:
            s = entry["dep"]

            # convert toml strings into expected types
            for k in set(entry).intersection(converters):
                if val := entry.get(k):
                    entry[k] = converters[k](val)

            passing_eapis = eapi_range(entry["eapis"])
            for eapi in EAPIS.values():
                if eapi in passing_eapis:
                    dep = Dep(s, eapi)
                    assert dep.category == entry.get("category")
                    assert dep.package == entry.get("package")
                    assert dep.blocker == entry.get("blocker")
                    assert dep.version == entry.get("version")
                    assert dep.revision == entry.get("revision")
                    assert dep.slot == entry.get("slot")
                    assert dep.subslot == entry.get("subslot")
                    assert dep.slot_op == entry.get("slot_op")
                    assert dep.use == entry.get("use")
                    assert str(dep) == s
                    assert repr(dep).startswith(f"<Dep {s!r} at 0x")
                else:
                    with pytest.raises(InvalidDep, match=f"invalid dep: {re.escape(s)}"):
                        Dep(s, eapi)

    def test_invalid(self, testdata_toml):
        for s in testdata_toml["dep.toml"]["invalid"]:
            for eapi in EAPIS.values():
                with pytest.raises(InvalidDep, match=f"invalid dep: {re.escape(s)}"):
                    Dep(s, eapi)

    def test_invalid_arg_type(self):
        for obj in (object(), None):
            with pytest.raises(TypeError):
                Dep(obj)

    def test_cmp(self, testdata_toml):
        for s in testdata_toml["dep.toml"]["compares"]:
            s1, op, s2 = s.split()
            d1 = Dep(s1)
            d2 = Dep(s2)
            for op_func in OperatorIterMap[op]:
                assert op_func(d1, d2), f"failed comparison: {s}"

        for s in testdata_toml["version.toml"]["compares"]:
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

    def test_intersects(self, testdata_toml):
        def parse(s):
            """Convert string to Dep falling back to Cpv."""
            try:
                return Dep(s)
            except InvalidDep:
                return Cpv(s)

        for d in testdata_toml["dep.toml"]["intersects"]:
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

    def test_sort(self, testdata_toml):
        for d in testdata_toml["dep.toml"]["sorting"]:
            expected = [Dep(s) for s in d["sorted"]]
            ordered = sorted(reversed(expected))
            if d["equal"]:
                # equal deps aren't sorted so reversing should restore the original order
                ordered = list(reversed(ordered))
            assert ordered == expected

    def test_hash(self, testdata_toml):
        for d in testdata_toml["version.toml"]["hashing"]:
            s = {Dep(f"=cat/pkg-{x}") for x in d["versions"]}
            length = 1 if d["equal"] else len(d["versions"])
            assert len(s) == length

    def test_cached(self):
        l = [Dep.cached("cat/pkg") for _ in range(1000)]
        assert len(l) == 1000

    def test_pickle(self):
        dep = Dep("=cat/pkg-1-r2:0/2=[a,b,c]")
        new_dep = pickle.loads(pickle.dumps(dep))
        assert dep == new_dep


class TestCpn:
    def test_init(self):
        dep = Cpn("cat/pkg")
        assert dep.category == "cat"
        assert dep.package == "pkg"
        assert dep.blocker is None
        assert dep.slot is None
        assert dep.subslot is None
        assert dep.slot_op is None
        assert dep.use is None
        assert dep.repo is None
        assert dep.version is None
        assert dep.revision is None
        assert dep.p == "pkg"
        assert dep.pf == "pkg"
        assert dep.pr is None
        assert dep.pv is None
        assert dep.pvr is None
        assert dep.cpn == "cat/pkg"
        assert dep.cpv == "cat/pkg"
        assert str(dep) == "cat/pkg"
        assert repr(dep).startswith("<Cpn 'cat/pkg' at 0x")

        # invalid
        for s in ("=cat/pkg-3", "cat/pkg-3", ""):
            with pytest.raises(ValueError, match="invalid unversioned dep"):
                Cpn(s)

    def test_pickle(self):
        dep = Cpn("cat/pkg")
        new_dep = pickle.loads(pickle.dumps(dep))
        assert dep == new_dep
