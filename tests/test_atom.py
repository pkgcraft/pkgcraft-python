import operator

import pytest

from pkgcraft import Atom


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
        assert a.fullver is None
        assert a.key == 'cat/pkg'
        assert a.cpv == 'cat/pkg'
        assert str(a) == 'cat/pkg'
        assert repr(a).startswith("<Atom 'cat/pkg' at 0x")

    def test_full(self):
        a = Atom('=cat/pkg-1:0/2=[use]::repo')
        assert a.category == 'cat'
        assert a.package == 'pkg'
        assert a.slot == '0'
        assert a.subslot == '2'
        assert a.slot_op == '='
        assert a.use_deps == ['use']
        assert a.repo == 'repo'
        assert a.fullver == '1'
        assert a.key == 'cat/pkg'
        assert a.cpv == 'cat/pkg-1'
        assert str(a) == '=cat/pkg-1:0/2=[use]::repo'
        assert repr(a).startswith("<Atom '=cat/pkg-1:0/2=[use]::repo' at 0x")

    def test_cmp(self):
        ops = {
            '<': operator.lt,
            '>': operator.gt,
            '==': operator.eq,
            '!=': operator.ne,
            '>=': operator.ge,
            '<=': operator.le,
        }

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
            op_func = ops[op]
            assert op_func(Atom(a), Atom(b)), f'failed comparison: {s}'
