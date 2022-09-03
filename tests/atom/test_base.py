import inspect
import pickle
import re

import pytest
# TODO: drop tomli usage when only supporting >=python-3.11
try:
    import tomllib
except ImportError:
    import tomli as tomllib

from pkgcraft.atom import Atom, Blocker, SlotOperator, Version, VersionWithOp
from pkgcraft.eapi import Eapi, EAPIS
from pkgcraft.error import InvalidAtom

from .. import TOMLDIR
from ..misc import OperatorIterMap


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
        assert a.slot_op is SlotOperator.Equal
        assert a.use == ('a', 'b', 'c')
        assert a.repo == 'repo'
        assert a.version == VersionWithOp('=1-r2')
        assert a.revision == '2'
        assert a.key == 'cat/pkg'
        assert a.cpv == 'cat/pkg-1-r2'
        assert str(a) == '!!=cat/pkg-1-r2:0/2=[a,b,c]::repo'
        assert repr(a).startswith("<Atom '!!=cat/pkg-1-r2:0/2=[a,b,c]::repo' at 0x")

    def test_valid(self):
        atom_attrs = []
        for (attr, val) in inspect.getmembers(Atom):
            if inspect.isgetsetdescriptor(val):
                atom_attrs.append(attr)

        with open(TOMLDIR / 'atoms.toml', 'rb') as f:
            d = tomllib.load(f)
        for entry in d['valid']:
            s = entry['atom']
            passing_eapis = Eapi.range(entry['eapis']).keys()
            for eapi in EAPIS:
                if eapi in passing_eapis:
                    a = Atom(s, eapi)
                    assert a.category == entry.get('category')
                    assert a.package == entry.get('package')
                    assert a.slot == entry.get('slot')
                    assert a.subslot == entry.get('subslot')
                    if version := entry.get('version'):
                        assert a.version == VersionWithOp(version)
                    else:
                        assert a.version is None
                    assert str(a) == s
                    assert repr(a).startswith(f"<Atom {s!r} at 0x")
                else:
                    with pytest.raises(InvalidAtom, match=f'invalid atom: "{re.escape(s)}"'):
                        Atom(s, eapi)

    def test_invalid(self):
        with open(TOMLDIR / 'atoms.toml', 'rb') as f:
            d = tomllib.load(f)
        for (s, eapi_range) in d['invalid']:
            failing_eapis = Eapi.range(eapi_range).keys()
            for eapi in EAPIS:
                if eapi in failing_eapis:
                    with pytest.raises(InvalidAtom, match=f'invalid atom: "{re.escape(s)}"'):
                        Atom(s, eapi)
                else:
                    assert Atom(s, eapi)

    def test_cmp(self):
        with open(TOMLDIR / 'versions.toml', 'rb') as f:
            d = tomllib.load(f)
        for s in d['compares']:
            v1, op, v2 = s.split()
            a1 = Atom(f'=cat/pkg-{v1}')
            a2 = Atom(f'=cat/pkg-{v2}')
            for op_func in OperatorIterMap[op]:
                assert op_func(a1, a2), f'failed comparison: {s}'

    def test_sort(self):
        with open(TOMLDIR / 'atoms.toml', 'rb') as f:
            d = tomllib.load(f)
        for (unsorted, expected) in d['sorting']:
            atoms = sorted(Atom(s) for s in unsorted)
            assert list(map(str, atoms)) == expected

    def test_hash(self):
        with open(TOMLDIR / 'versions.toml', 'rb') as f:
            d = tomllib.load(f)
        for (versions, size) in d['hashing']:
            s = {Atom(f'=cat/pkg-{x}') for x in versions}
            assert len(s) == size

    def test_cached(self):
        l = [Atom.cached('cat/pkg') for _ in range(1000)]
        assert len(l) == 1000

    def test_pickle(self):
        a = Atom('=cat/pkg-1-r2:0/2=[a,b,c]')
        b = pickle.loads(pickle.dumps(a))
        assert a == b
