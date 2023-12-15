import itertools
import pickle

import pytest

from pkgcraft.dep import *
from pkgcraft.error import InvalidVersion

from ..misc import TEST_DATA, OperatorIterMap, OperatorMap


class TestOperator:
    def test_from_str(self):
        # valid
        assert Operator.from_str("=*") == Operator.EqualGlob
        assert Operator.from_str("~") == Operator.Approximate

        # invalid
        for s in ("", "*", "><"):
            with pytest.raises(ValueError):
                Operator.from_str(s)

        # invalid args
        for obj in [None, object()]:
            with pytest.raises(TypeError):
                Operator.from_str(obj)


class TestVersion:
    def test_new_and_parse(self):
        # no revision
        ver = Version("1")
        assert ver.op is None
        assert ver.base == "1"
        assert ver.revision is None
        assert str(ver) == "1"
        assert "Version '1' at 0x" in repr(ver)

        # revisioned
        ver = Version("1-r1")
        assert ver.op is None
        assert ver.base == "1"
        assert ver.revision == Revision("1")
        assert str(ver) == "1-r1"
        assert "Version '1-r1' at 0x" in repr(ver)

        # explicit '0' revision
        ver = Version("1-r0")
        assert ver.op is None
        assert ver.base == "1"
        assert ver.revision == Revision("0")
        assert str(ver) == "1-r0"
        assert "Version '1-r0' at 0x" in repr(ver)

        # unrevisioned with operator
        ver = Version("<1_alpha")
        assert ver.op == "<"
        assert ver.base == "1_alpha"
        assert ver.revision is None
        assert str(ver) == "<1_alpha"
        assert "Version '<1_alpha' at 0x" in repr(ver)

        # revisioned with operator
        ver = Version(">=1_beta2-r3")
        assert ver.op == ">="
        assert ver.base == "1_beta2"
        assert ver.revision == Revision("3")
        assert str(ver) == ">=1_beta2-r3"
        assert "Version '>=1_beta2-r3' at 0x" in repr(ver)

        # valid
        for s in TEST_DATA.toml("version.toml")["valid"]:
            assert Version.parse(s), f"{s} isn't valid"
            Version(s)

        # invalid
        for s in TEST_DATA.toml("version.toml")["invalid"]:
            assert not Version.parse(s), f"{s} is valid"
            with pytest.raises(InvalidVersion, match=f"invalid version: {s}"):
                Version.parse(s, raised=True)
            with pytest.raises(InvalidVersion, match=f"invalid version: {s}"):
                Version(s)

        # invalid types
        for obj in (object(), None):
            with pytest.raises(TypeError):
                Version(obj)
            with pytest.raises(TypeError):
                Version.parse(obj)

    def test_cmp(self):
        for s in TEST_DATA.toml("version.toml")["compares"]:
            s1, op, s2 = s.split()
            ver1 = Version(s1)
            ver2 = Version(s2)
            for op_func in OperatorIterMap[op]:
                assert op_func(ver1, ver2), f"failed comparison: {s}"

        # verify incompatible type comparisons
        obj = Version("0")
        for op, op_func in OperatorMap.items():
            if op == "==":
                assert not op_func(obj, None)
            elif op == "!=":
                assert op_func(obj, None)
            else:
                with pytest.raises(TypeError):
                    op_func(obj, None)

    def test_intersects(self):
        for d in TEST_DATA.toml("version.toml")["intersects"]:
            # test intersections between all pairs of distinct values
            for s1, s2 in itertools.permutations(d["vals"], 2):
                (ver1, ver2) = (Version(s1), Version(s2))

                # elements intersect themselves
                assert ver1.intersects(ver1)
                assert ver2.intersects(ver2)

                # intersect or not depending on status
                if d["status"]:
                    assert ver1.intersects(ver2)
                else:
                    assert not ver1.intersects(ver2)

        # invalid args
        v = Version("1")
        for obj in [None, object()]:
            with pytest.raises(TypeError):
                v.intersects(obj)

    def test_sort(self):
        for d in TEST_DATA.toml("version.toml")["sorting"]:
            expected = [Version(s) for s in d["sorted"]]
            ordered = sorted(reversed(expected))
            if d["equal"]:
                # equal versions aren't sorted so reversing should restore the original order
                ordered = list(reversed(ordered))
            assert ordered == expected

    def test_hash(self):
        for d in TEST_DATA.toml("version.toml")["hashing"]:
            vers = {Version(x) for x in d["versions"]}
            length = 1 if d["equal"] else len(d["versions"])
            assert len(vers) == length

    def test_pickle(self):
        for s in ("1-r1", ">=1-r1"):
            ver1 = Version(s)
            ver2 = pickle.loads(pickle.dumps(ver1))
            assert ver1 == ver2


class TestRevision:
    def test_creation(self):
        # valid
        for s in ("", "0", "00", "1", "01", "10"):
            rev = Revision(s)
            assert str(rev) == s
            assert f"Revision '{s}' at 0x" in repr(rev)
            assert bool(s) == bool(rev)

        # invalid
        for s in ("a", "1a", "1.0"):
            with pytest.raises(InvalidVersion):
                Revision(s)

        # invalid args
        for obj in [None, object()]:
            with pytest.raises(TypeError):
                Revision(obj)

    def test_cmp(self):
        # nonexistent revision equal to '0'
        assert Revision("") == Revision("0") == Revision("00")
        # nonexistent revision equal to None, but explicit '0' is not
        assert Revision("") == None
        assert Revision("0") != None

        rev1 = Revision("1")
        rev2 = Revision("2")
        obj = object()

        assert rev1 < rev2
        with pytest.raises(TypeError):
            assert rev1 < obj

        assert rev1 <= rev2
        assert rev2 <= rev2
        with pytest.raises(TypeError):
            assert rev1 <= obj

        assert rev1 == rev1
        assert not rev1 == obj

        assert rev1 != rev2
        assert rev1 != obj

        assert rev2 >= rev1
        assert rev2 >= rev2
        with pytest.raises(TypeError):
            assert rev2 >= obj

        assert rev2 > rev1
        with pytest.raises(TypeError):
            assert rev2 > obj

    def test_hash(self):
        revs = {Revision(s) for s in ["", "0", "00"]}
        assert len(revs) == 1
        revs = {Revision(s) for s in ["0", "01", "10", "11"]}
        assert len(revs) == 4

    def test_pickle(self):
        rev1 = Revision("1")
        rev2 = pickle.loads(pickle.dumps(rev1))
        assert rev1 == rev2
