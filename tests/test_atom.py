import operator

import pytest

from pkgcraft import Atom, PkgcraftError, Version

OperatorMap = {
    '<': operator.lt,
    '>': operator.gt,
    '==': operator.eq,
    '!=': operator.ne,
    '>=': operator.ge,
    '<=': operator.le,
}


class TestAtom:

    def test_no_version(self):
        a = Atom('cat/pkg')
        assert a.category == 'cat'
        assert a.package == 'pkg'
        assert a.slot is None
        assert a.subslot is None
        assert a.slot_op is None
        assert a.use_deps is None
        assert a.repo is None
        assert a.version is None
        assert a.key == 'cat/pkg'
        assert a.cpv == 'cat/pkg'
        assert str(a) == 'cat/pkg'
        assert repr(a).startswith("<Atom 'cat/pkg' at 0x")

    def test_full(self):
        a = Atom('=cat/pkg-1:0/2=[a,b,c]::repo')
        assert a.category == 'cat'
        assert a.package == 'pkg'
        assert a.slot == '0'
        assert a.subslot == '2'
        assert a.slot_op == '='
        assert a.use_deps == ['a', 'b', 'c']
        assert a.repo == 'repo'
        assert a.version == '1'
        assert a.key == 'cat/pkg'
        assert a.cpv == 'cat/pkg-1'
        assert str(a) == '=cat/pkg-1:0/2=[a,b,c]::repo'
        assert repr(a).startswith("<Atom '=cat/pkg-1:0/2=[a,b,c]::repo' at 0x")

    def test_invalid(self):
        for s in ('invalid', 'cat-1'):
            with pytest.raises(PkgcraftError, match=f'invalid atom: "{s}"'):
                Atom(s)

    def test_cmp(self):
        for s in (
                '=cat/pkg-0 < =cat/pkg-1',
                '=cat/pkg-0 <= =cat/pkg-1',
                '=cat/pkg-1 <= =cat/pkg-1-r0',
                '=cat/pkg-1 == =cat/pkg-1-r0',
                '=cat/pkg-1 >= =cat/pkg-1-r0',
                '=cat/pkg-1.0 >= =cat/pkg-1',
                '=cat/pkg-1.0 > =cat/pkg-1',
                '=cat/pkg-1.0 != =cat/pkg-1',
                ):
            a, op, b = s.split()
            op_func = OperatorMap[op]
            assert op_func(Atom(a), Atom(b)), f'failed comparison: {s}'

        for (unsorted, expected) in (
                (("=a/b-1_p2", "=a/b-1_p1", "=a/b-1_p0"), ("=a/b-1_p0", "=a/b-1_p1", "=a/b-1_p2")),
                (("=a/b-1-r2", "=a/b-1-r1", "=a/b-1-r0"), ("=a/b-1-r0", "=a/b-1-r1", "=a/b-1-r2")),
                ):
            atoms = sorted(Atom(s) for s in unsorted)
            assert tuple(map(str, atoms)) == expected


class TestVersion:

    def test_invalid(self):
        for s in ('-1', '1a1'):
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
