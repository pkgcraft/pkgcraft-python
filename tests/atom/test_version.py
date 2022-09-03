import operator
import pickle

import pytest
# TODO: drop tomli usage when only supporting >=python-3.11
try:
    import tomllib
except ImportError:
    import tomli as tomllib

from pkgcraft.error import PkgcraftError
from pkgcraft.atom import Version, VersionWithOp

from .. import TOMLDIR
from ..misc import OperatorIterMap


class TestVersion:

    def test_creation(self):
        # no revision
        v = Version('1')
        assert v.revision == '0'
        assert str(v) == '1'
        assert repr(v).startswith("<Version '1' at 0x")

        # revisioned
        v = Version('1-r1')
        assert v.revision == '1'
        assert str(v) == '1-r1'
        assert repr(v).startswith("<Version '1-r1' at 0x")

        # explicit '0' revision
        v = Version('1-r0')
        assert v.revision == '0'
        assert str(v) == '1-r0'
        assert repr(v).startswith("<Version '1-r0' at 0x")

    def test_invalid(self):
        for s in ('-1', '1a1', 'a', '>1-r2'):
            with pytest.raises(PkgcraftError, match=f'invalid version: "{s}"'):
                Version(s)

    def test_cmp(self):
        with open(TOMLDIR / 'versions.toml', 'rb') as f:
            d = tomllib.load(f)
        for s in d['compares']:
            a, op, b = s.split()
            v1 = Version(a)
            v2 = Version(b)
            for op_func in OperatorIterMap[op]:
                assert op_func(v1, v2), f'failed comparison: {s}'

    def test_sort(self):
        with open(TOMLDIR / 'versions.toml', 'rb') as f:
            d = tomllib.load(f)
        for (unsorted, expected) in d['sorting']:
            versions = sorted(Version(s) for s in unsorted)
            assert list(map(str, versions)) == expected

    def test_hash(self):
        with open(TOMLDIR / 'versions.toml', 'rb') as f:
            d = tomllib.load(f)
        for (versions, size) in d['hashing']:
            s = {Version(x) for x in versions}
            assert len(s) == size

    def test_pickle(self):
        a = Version('1-r1')
        b = pickle.loads(pickle.dumps(a))
        assert a == b


class TestVersionWithOp:

    def test_invalid(self):
        for s in ('1-r2',):
            with pytest.raises(PkgcraftError, match=f'invalid version: "{s}"'):
                VersionWithOp(s)

    def test_pickle(self):
        a = VersionWithOp('>=1-r1')
        b = pickle.loads(pickle.dumps(a))
        assert a == b
