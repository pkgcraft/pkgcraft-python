import itertools
import pickle

import pytest

from pkgcraft.atom import Version, VersionWithOp
from pkgcraft.error import InvalidVersion

from ..misc import OperatorIterMap


class TestVersion:
    def test_creation(self):
        # no revision
        v = Version("1")
        assert v.revision == "0"
        assert str(v) == "1"
        assert repr(v).startswith("<Version '1' at 0x")

        # revisioned
        v = Version("1-r1")
        assert v.revision == "1"
        assert str(v) == "1-r1"
        assert repr(v).startswith("<Version '1-r1' at 0x")

        # explicit '0' revision
        v = Version("1-r0")
        assert v.revision == "0"
        assert str(v) == "1-r0"
        assert repr(v).startswith("<Version '1-r0' at 0x")

    def test_invalid(self):
        for s in ("-1", "1a1", "a", ">1-r2"):
            with pytest.raises(InvalidVersion, match=f"invalid version: {s}"):
                Version(s)

    def test_invalid_arg_type(self):
        for obj in (object(), None):
            with pytest.raises(TypeError):
                Version(obj)

    def test_cmp(self, toml_data):
        for s in toml_data["version.toml"]["compares"]:
            a, op, b = s.split()
            v1 = Version(a)
            v2 = Version(b)
            for op_func in OperatorIterMap[op]:
                assert op_func(v1, v2), f"failed comparison: {s}"

    def test_intersects(self, toml_data):
        def parse(s):
            """Convert string to non-op version falling back to op-ed version."""
            try:
                return Version(s)
            except InvalidVersion:
                return VersionWithOp(s)

        for d in toml_data["version.toml"]["intersects"]:
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
        for d in toml_data["version.toml"]["sorting"]:
            expected = [Version(s) for s in d["sorted"]]
            ordered = sorted(reversed(expected))
            if d["equal"]:
                # equal versions aren't sorted so reversing should restore the original order
                ordered = list(reversed(ordered))
            assert ordered == expected

    def test_hash(self, toml_data):
        for d in toml_data["version.toml"]["hashing"]:
            s = {Version(x) for x in d["versions"]}
            length = 1 if d["equal"] else len(d["versions"])
            assert len(s) == length

    def test_pickle(self):
        a = Version("1-r1")
        b = pickle.loads(pickle.dumps(a))
        assert a == b


class TestVersionWithOp:
    def test_invalid(self):
        for s in ("1-r2",):
            with pytest.raises(InvalidVersion, match=f"invalid version: {s}"):
                VersionWithOp(s)

    def test_invalid_arg_type(self):
        for obj in (object(), None):
            with pytest.raises(TypeError):
                VersionWithOp(obj)

    def test_pickle(self):
        a = VersionWithOp(">=1-r1")
        b = pickle.loads(pickle.dumps(a))
        assert a == b
