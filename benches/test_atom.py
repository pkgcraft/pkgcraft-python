import binascii
import os

import pytest

from pkgcraft import Atom as pkgcraft_atom
from pkgcore.ebuild.atom import atom as pkgcore_atom
from portage.dep import Atom as portage_atom

def random_pkg(func):
    cat = binascii.b2a_hex(os.urandom(10)).decode()
    pkg = binascii.b2a_hex(os.urandom(10)).decode()
    s = f'={cat}/{pkg}-1-r2:3/4=[a,b,c]'
    func(s)

atom_funcs = [
    ('pkgcraft', pkgcraft_atom),
    ('pkgcore', pkgcore_atom),
    ('portage', portage_atom),
]

@pytest.mark.parametrize("lib,func", atom_funcs)
def test_bench_atom_static(benchmark, lib, func):
    benchmark(func, '=cat/pkg-1-r2:3/4=[a,b,c]')

@pytest.mark.parametrize("lib,func", atom_funcs)
def test_bench_atom_random(benchmark, lib, func):
    benchmark(random_pkg, func)
