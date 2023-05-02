import itertools
import pickle

import pytest

from pkgcraft.dep import Operator, Version
from pkgcraft.error import InvalidVersion

from ..misc import OperatorIterMap, OperatorMap


class TestOperator:
    def test_from_str(self):
        # valid
        assert Operator.from_str("=*") == Operator.EqualGlob
        assert Operator.from_str("~") == Operator.Approximate

        # invalid
        for s in ("", "*", "><"):
            with pytest.raises(ValueError):
                Operator.from_str(s)


class TestVersion:
    def test_creation(self):
        # no revision
        v = Version("1")
        assert v.op is None
        assert v.base == "1"
        assert v.revision is None
        assert str(v) == "1"
        assert repr(v).startswith("<Version '1' at 0x")

        # revisioned
        v = Version("1-r1")
        assert v.op is None
        assert v.base == "1"
        assert v.revision == "1"
        assert str(v) == "1-r1"
        assert repr(v).startswith("<Version '1-r1' at 0x")

        # explicit '0' revision
        v = Version("1-r0")
        assert v.op is None
        assert v.base == "1"
        assert v.revision == "0"
        assert str(v) == "1-r0"
        assert repr(v).startswith("<Version '1-r0' at 0x")

        # unrevisioned with operator
        v = Version("<1_alpha")
        assert v.op == "<"
        assert v.base == "1_alpha"
        assert v.revision is None
        assert str(v) == "<1_alpha"
        assert repr(v).startswith("<Version '<1_alpha' at 0x")

        # revisioned with operator
        v = Version(">=1_beta2-r3")
        assert v.op == ">="
        assert v.base == "1_beta2"
        assert v.revision == "3"
        assert str(v) == ">=1_beta2-r3"
        assert repr(v).startswith("<Version '>=1_beta2-r3' at 0x")

    def test_invalid(self):
        for s in ("-1", "1a1", "a"):
            with pytest.raises(InvalidVersion, match=f"invalid version: {s}"):
                Version(s)

    def test_invalid_arg_type(self):
        for obj in (object(), None):
            with pytest.raises(TypeError):
                Version(obj)

    def test_cmp(self, testdata_toml):
        for s in testdata_toml["version.toml"]["compares"]:
            a, op, b = s.split()
            v1 = Version(a)
            v2 = Version(b)
            for op_func in OperatorIterMap[op]:
                assert op_func(v1, v2), f"failed comparison: {s}"

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

    def test_intersects(self, testdata_toml):
        for d in testdata_toml["version.toml"]["intersects"]:
            # test intersections between all pairs of distinct values
            for s1, s2 in itertools.permutations(d["vals"], 2):
                (v1, v2) = (Version(s1), Version(s2))

                # elements intersect themselves
                assert v1.intersects(v1)
                assert v2.intersects(v2)

                # intersect or not depending on status
                if d["status"]:
                    assert v1.intersects(v2)
                else:
                    assert not v1.intersects(v2)

    def test_sort(self, testdata_toml):
        for d in testdata_toml["version.toml"]["sorting"]:
            expected = [Version(s) for s in d["sorted"]]
            ordered = sorted(reversed(expected))
            if d["equal"]:
                # equal versions aren't sorted so reversing should restore the original order
                ordered = list(reversed(ordered))
            assert ordered == expected

    def test_hash(self, testdata_toml):
        for d in testdata_toml["version.toml"]["hashing"]:
            s = {Version(x) for x in d["versions"]}
            length = 1 if d["equal"] else len(d["versions"])
            assert len(s) == length

    def test_pickle(self):
        for s in ("1-r1", ">=1-r1"):
            a = Version(s)
            b = pickle.loads(pickle.dumps(a))
            assert a == b
