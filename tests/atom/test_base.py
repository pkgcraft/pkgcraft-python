import inspect
import itertools
import pickle
import re

import pytest

from pkgcraft.atom import Atom, Blocker, Cpv, SlotOperator, VersionWithOp
from pkgcraft.eapi import EAPIS, Eapi
from pkgcraft.error import InvalidAtom, InvalidCpv
from pkgcraft.restrict import Restrict

from ..misc import OperatorIterMap


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


class TestAtom:
    def test_init(self):
        # no version
        a = Atom("cat/pkg")
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
        assert a.cpn == "cat/pkg"
        assert a.cpv == "cat/pkg"
        assert str(a) == "cat/pkg"
        assert repr(a).startswith("<Atom 'cat/pkg' at 0x")

        # all fields -- extended EAPI default allows repo deps
        a = Atom("!!=cat/pkg-1-r2:0/2=[a,b,c]::repo")
        assert a.category == "cat"
        assert a.package == "pkg"
        assert a.blocker is Blocker.Strong
        assert a.slot == "0"
        assert a.subslot == "2"
        assert a.slot_op is SlotOperator.Equal
        assert a.use == ("a", "b", "c")
        assert a.repo == "repo"
        assert a.version == VersionWithOp("=1-r2")
        assert a.revision == "2"
        assert a.cpn == "cat/pkg"
        assert a.cpv == "cat/pkg-1-r2"
        assert str(a) == "!!=cat/pkg-1-r2:0/2=[a,b,c]::repo"
        assert repr(a).startswith("<Atom '!!=cat/pkg-1-r2:0/2=[a,b,c]::repo' at 0x")

        # explicitly specifying an official EAPI fails
        for eapi in ("8", EAPIS["8"]):
            with pytest.raises(InvalidAtom):
                Atom("cat/pkg::repo", eapi)

        # unknown EAPI
        with pytest.raises(ValueError, match=f"unknown EAPI"):
            Atom("cat/pkg", "nonexistent")

        # invalid EAPI type
        with pytest.raises(TypeError):
            Atom("cat/pkg", object())

    def test_matches(self):
        a = Atom("=cat/pkg-1")
        r = Restrict(a)
        assert a.matches(r)
        assert not a.matches(~r)

    def test_valid(self, toml_data):
        atom_attrs = []
        for (attr, val) in inspect.getmembers(Atom):
            if inspect.isgetsetdescriptor(val):
                atom_attrs.append(attr)

        # converters for toml data
        converters = {
            "blocker": lambda x: Blocker.from_str(x),
            "version": lambda x: VersionWithOp(x),
            "slot_op": lambda x: SlotOperator.from_str(x),
            "use": lambda x: tuple(x),
        }

        for entry in toml_data["atom.toml"]["valid"]:
            s = entry["atom"]

            # convert toml strings into expected types
            for k in set(entry).intersection(converters):
                if val := entry.get(k):
                    entry[k] = converters[k](val)

            passing_eapis = Eapi.range(entry["eapis"])
            for eapi in EAPIS.values():
                if eapi in passing_eapis:
                    a = Atom(s, eapi)
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
                    assert repr(a).startswith(f"<Atom {s!r} at 0x")
                else:
                    with pytest.raises(InvalidAtom, match=f"invalid atom: {re.escape(s)}"):
                        Atom(s, eapi)

    def test_invalid(self, toml_data):
        for s in toml_data["atom.toml"]["invalid"]:
            for eapi in EAPIS.values():
                with pytest.raises(InvalidAtom, match=f"invalid atom: {re.escape(s)}"):
                    Atom(s, eapi)

    def test_invalid_arg_type(self):
        for obj in (object(), None):
            with pytest.raises(TypeError):
                Atom(obj)

    def test_cmp(self, toml_data):
        for s in toml_data["version.toml"]["compares"]:
            v1, op, v2 = s.split()
            a1 = Atom(f"=cat/pkg-{v1}")
            a2 = Atom(f"=cat/pkg-{v2}")
            for op_func in OperatorIterMap[op]:
                assert op_func(a1, a2), f"failed comparison: {s}"

    def test_intersects(self, toml_data):
        def parse(s):
            """Convert string to CPV falling back to regular atom."""
            try:
                return Cpv(s)
            except InvalidCpv:
                return Atom(s)

        for d in toml_data["atom.toml"]["intersects"]:
            # test intersections between all pairs of distinct values
            for (s1, s2) in itertools.permutations(d["vals"], 2):
                (v1, v2) = (parse(s1), parse(s2))

                # elements intersect themselves
                assert v1.intersects(v1)
                assert v2.intersects(v2)

                # intersect or not depending on status
                if d["status"]:
                    assert v1.intersects(v2)
                else:
                    assert not v1.intersects(v2)

    def test_sort(self, toml_data):
        for d in toml_data["atom.toml"]["sorting"]:
            expected = [Atom(s) for s in d["sorted"]]
            ordered = sorted(reversed(expected))
            if d["equal"]:
                # equal atoms aren't sorted so reversing should restore the original order
                ordered = list(reversed(ordered))
            assert ordered == expected

    def test_hash(self, toml_data):
        for d in toml_data["version.toml"]["hashing"]:
            s = {Atom(f"=cat/pkg-{x}") for x in d["versions"]}
            length = 1 if d["equal"] else len(d["versions"])
            assert len(s) == length

    def test_cached(self):
        l = [Atom.cached("cat/pkg") for _ in range(1000)]
        assert len(l) == 1000

    def test_pickle(self):
        a = Atom("=cat/pkg-1-r2:0/2=[a,b,c]")
        b = pickle.loads(pickle.dumps(a))
        assert a == b
