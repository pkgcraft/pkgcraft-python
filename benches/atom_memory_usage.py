# Script to roughly benchmark memory usage for atom instances between pkgcraft,
# pkgcore, and portage.

import os
import sys
import time

import humanize
from pkgcraft.atom import Atom as pkgcraft_atom
from pkgcore.ebuild.atom import atom as pkgcore_atom
from portage.dep import Atom as portage_atom
import psutil

atom_funcs = [
    ('pkgcraft', pkgcraft_atom),
    ('pkgcraft-cached', pkgcraft_atom.cached),
    ('pkgcore', pkgcore_atom),
    ('portage', portage_atom),
]

def test(atoms):
    for (impl, func) in atom_funcs:
        pid = os.fork()
        if pid:
            os.wait()
        else:
            start = time.time()
            l = [func(x) for x in atoms]
            total = time.time() - start
            proc = psutil.Process()
            size = humanize.naturalsize(proc.memory_info().rss)
            print(f"{impl}: {size} ({total:.{2}f}s)")
            sys.exit()


if __name__ == '__main__':
    num_atoms = 1000000

    print(f"\nStatic atoms ({num_atoms})\n======================")
    test(('cat/pkg' for _ in range(num_atoms)))

    print(f"\nDynamic atoms ({num_atoms})\n=======================")
    test((f'=cat/pkg-{x}-r1:2/3[a,b,c]' for x in range(num_atoms)))
