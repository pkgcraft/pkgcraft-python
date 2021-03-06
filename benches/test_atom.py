import binascii
import os

import pytest

from pkgcraft.atom import Atom as pkgcraft_atom
from pkgcore.ebuild.atom import atom as pkgcore_atom
from portage.dep import Atom as portage_atom

def random_atom(func):
    cat = binascii.b2a_hex(os.urandom(10)).decode()
    pkg = binascii.b2a_hex(os.urandom(10)).decode()
    s = f'=cat_{cat}/pkg_{pkg}-1-r2:3/4=[a,b,c]'
    return func(s)

def random_cp(func):
    cat = binascii.b2a_hex(os.urandom(10)).decode()
    pkg = binascii.b2a_hex(os.urandom(10)).decode()
    s = f'cat_{cat}/pkg_{pkg}'
    return func(s)

atom_funcs = [
    ('pkgcraft', pkgcraft_atom),
    ('pkgcraft', pkgcraft_atom.cached),
    ('pkgcore', pkgcore_atom),
    ('portage', portage_atom),
]

@pytest.mark.parametrize("lib,func", atom_funcs)
def test_bench_atom_static(benchmark, lib, func):
    benchmark(func, '=cat/pkg-1-r2:3/4=[a,b,c]')

@pytest.mark.parametrize("lib,func", atom_funcs)
def test_bench_atom_random(benchmark, lib, func):
    benchmark(random_atom, func)

@pytest.mark.parametrize("lib,func", atom_funcs)
def test_bench_atom_property(benchmark, lib, func):
    atom = func('=cat/pkg-1-r2:3/4=[a,b,c]')
    version = benchmark(getattr, atom, 'version')
    assert str(version).startswith('1')

@pytest.mark.parametrize("lib,func", atom_funcs)
def test_bench_atom_property_none(benchmark, lib, func):
    atom = func('cat/pkg')
    version = benchmark(getattr, atom, 'version')
    assert version is None

# portage atoms don't natively support comparisons
@pytest.mark.parametrize("lib,func", (('pkgcraft', pkgcraft_atom), ('pkgcore', pkgcore_atom)))
def test_bench_atom_sorting_worst_case(benchmark, lib, func):
    atoms = [func(f'=cat/pkg-{v}-r1:2/3=[a,b,c]') for v in reversed(range(100))]
    result = benchmark(sorted, atoms)
    assert result == list(reversed(atoms))

# portage atoms don't natively support comparisons
@pytest.mark.parametrize("lib,func", (('pkgcraft', pkgcraft_atom), ('pkgcore', pkgcore_atom)))
def test_bench_atom_sorting_best_case(benchmark, lib, func):
    atoms = [func(f'=cat/pkg-{v}-r1:2/3=[a,b,c]') for v in range(100)]
    result = benchmark(sorted, atoms)
    assert result == atoms
