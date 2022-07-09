import operator
import pickle

import pytest

from pkgcraft.error import PkgcraftError
from pkgcraft.atom import Version, VersionWithOp

OperatorMap = {
    '<': operator.lt,
    '>': operator.gt,
    '==': operator.eq,
    '!=': operator.ne,
    '>=': operator.ge,
    '<=': operator.le,
}


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
        for s in (
                '0 < 1',
                '0 <= 1',
                '1 <= 1-r0',
                '1 == 1-r0',
                '1 >= 1-r0',
                '1.0 >= 1',
                '1.0 > 1',
                '1.0 != 1',
                ):
            a, op, b = s.split()
            op_func = OperatorMap[op]
            assert op_func(Version(a), Version(b)), f'failed comparison: {s}'

        for (unsorted, expected) in (
                (("1_p2", "1_p1", "1_p0"), ("1_p0", "1_p1", "1_p2")),
                (("1-r2", "1-r1", "1-r0"), ("1-r0", "1-r1", "1-r2")),
                ):
            versions = sorted(Version(s) for s in unsorted)
            assert tuple(map(str, versions)) == expected

    def test_hash(self):
        for equal_versions in (
                ('0', '0-r0', '0-r00'),
                ('1', '01', '001'),
                ('1.0', '1.00'),
                ('0001.1', '1.1'),
                ('0_beta1', '0_beta01', '0_beta001'),
                ('1.0.2', '1.0.2-r0', '1.000.2', '1.00.2-r0'),
                ):
            s = {Version(x) for x in equal_versions}
            assert len(s) == 1

        for unequal_versions in (
                ('0', '1'),
                ('1.01.2', '1.010.02'),
                ('1.0', '1'),
                ('0.1', '0.01', '0.001'),
                ):
            s = {Version(x) for x in unequal_versions}
            assert len(s) == len(unequal_versions)

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
        with pytest.raises(NotImplementedError):
            pickle.dumps(a)
