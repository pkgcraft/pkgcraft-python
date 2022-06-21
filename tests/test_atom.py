import operator

import pytest
import re

from pkgcraft.atom import Atom, Blocker, Cpv
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


class TestAtom:

    def test_new(self):
        # no version
        a = Atom('cat/pkg')
        assert a.category == 'cat'
        assert a.package == 'pkg'
        assert a.blocker is None
        assert a.slot is None
        assert a.subslot is None
        assert a.slot_op is None
        assert a.use is None
        assert a.repo is None
        assert a.version is None
        assert a.revision is None
        assert a.key == 'cat/pkg'
        assert a.cpv == 'cat/pkg'
        assert str(a) == 'cat/pkg'
        assert repr(a).startswith("<Atom 'cat/pkg' at 0x")

        # all fields
        a = Atom('!!=cat/pkg-1-r2:0/2=[a,b,c]::repo', 'pkgcraft')
        assert a.category == 'cat'
        assert a.package == 'pkg'
        assert a.blocker is Blocker.Strong
        assert a.slot == '0'
        assert a.subslot == '2'
        assert a.slot_op == '='
        assert a.use == ('a', 'b', 'c')
        assert a.repo == 'repo'
        assert a.version == VersionWithOp('=1-r2')
        assert a.revision == '2'
        assert a.key == 'cat/pkg'
        assert a.cpv == 'cat/pkg-1-r2'
        assert str(a) == '!!=cat/pkg-1-r2:0/2=[a,b,c]::repo'
        assert repr(a).startswith("<Atom '!!=cat/pkg-1-r2:0/2=[a,b,c]::repo' at 0x")

    def test_invalid(self):
        for s in ('invalid', 'cat-1', 'cat/pkg-1'):
            with pytest.raises(PkgcraftError, match=f'invalid atom: "{s}"'):
                Atom(s)

        # EAPI invalid
        for (s, eapi) in (
                ('cat/pkg:0', '0'), # slot deps in EAPI >= 1
                ('!cat/pkg', '1'), # blockers in EAPI >= 2
                ('cat/pkg[use]', '1'), # use deps in EAPI >= 2
                ('cat/pkg[use(+)]', '3'), # use dep defaults in EAPI >= 4
                ('cat/pkg:0/1', '4'), # subslot deps in EAPI >= 5
                ('cat/pkg:0=', '4'), # slot operators in EAPI >= 5
                ('cat/pkg::repo', '8'), # repo deps in no official EAPI
                ):
            with pytest.raises(PkgcraftError, match=f'invalid atom: "{re.escape(s)}"'):
                Atom(s, eapi)

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

    def test_hash(self):
        for equal_versions in (
                ('0', '0-r0', '0-r00'),
                ('1', '01', '001'),
                ('1.0', '1.00'),
                ('0001.1', '1.1'),
                ('0_beta1', '0_beta01', '0_beta001'),
                ('1.0.2', '1.0.2-r0', '1.000.2', '1.00.2-r0'),
                ):
            s = {Atom(f'=cat/pkg-{x}') for x in equal_versions}
            assert len(s) == 1

        for unequal_versions in (
                ('0', '1'),
                ('1.01.2', '1.010.02'),
                ('1.0', '1'),
                ('0.1', '0.01', '0.001'),
                ):
            s = {Atom(f'=cat/pkg-{x}') for x in unequal_versions}
            assert len(s) == len(unequal_versions)


class TestCpv:

    def test_new(self):
        a = Cpv('cat/pkg-1-r2')
        assert a.category == 'cat'
        assert a.package == 'pkg'
        assert a.version == Version('1-r2')
        assert a.revision == '2'
        assert a.key == 'cat/pkg'
        assert str(a) == 'cat/pkg-1-r2'
        assert repr(a).startswith("<Cpv 'cat/pkg-1-r2' at 0x")

    def test_invalid(self):
        for s in ('invalid', 'cat-1', 'cat/pkg', '=cat/pkg-1'):
            with pytest.raises(PkgcraftError, match=f'invalid cpv: "{s}"'):
                Cpv(s)
