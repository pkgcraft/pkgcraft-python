import pickle

import pytest

from pkgcraft.atom import Version, VersionWithOp
from pkgcraft.error import InvalidVersion

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
            with pytest.raises(InvalidVersion, match=f'invalid version: {s}'):
                Version(s)

    def test_invalid_arg_type(self):
        for obj in (object(), None):
            with pytest.raises(TypeError):
                Version(obj)

    def test_cmp(self, toml_data):
        for s in toml_data['version.toml']['compares']:
            a, op, b = s.split()
            v1 = Version(a)
            v2 = Version(b)
            for op_func in OperatorIterMap[op]:
                assert op_func(v1, v2), f'failed comparison: {s}'

    def test_sort(self, toml_data):
        for (unsorted, expected) in toml_data['version.toml']['sorting']:
            assert sorted(map(Version, unsorted)) == [Version(s) for s in expected]

    def test_hash(self, toml_data):
        for (versions, size) in toml_data['version.toml']['hashing']:
            s = {Version(x) for x in versions}
            assert len(s) == size

    def test_pickle(self):
        a = Version('1-r1')
        b = pickle.loads(pickle.dumps(a))
        assert a == b


class TestVersionWithOp:

    def test_invalid(self):
        for s in ('1-r2',):
            with pytest.raises(InvalidVersion, match=f'invalid version: {s}'):
                VersionWithOp(s)

    def test_invalid_arg_type(self):
        for obj in (object(), None):
            with pytest.raises(TypeError):
                VersionWithOp(obj)

    def test_pickle(self):
        a = VersionWithOp('>=1-r1')
        b = pickle.loads(pickle.dumps(a))
        assert a == b
