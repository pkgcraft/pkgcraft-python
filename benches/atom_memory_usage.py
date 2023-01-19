# Script to roughly benchmark memory usage for atom instances between pkgcraft,
# pkgcore, and portage.

import os
import sys
import time
from random import randrange

import humanize
import psutil
from pkgcore.ebuild.atom import atom as pkgcore_atom
from portage.dep import Atom as portage_atom

from pkgcraft.atom import Atom as pkgcraft_atom

eprint = lambda x: print(x, file=sys.stderr)

atom_funcs = [
    ("pkgcraft", pkgcraft_atom),
    ("pkgcraft-cached", pkgcraft_atom.cached),
    ("pkgcore", pkgcore_atom),
    ("portage", portage_atom),
]


def test(atoms):
    eprint("---------------------------------------")
    eprint("{:<20} {:<10} time".format("implementation", "memory"))
    eprint("---------------------------------------")
    for (impl, func) in atom_funcs:
        if pid := os.fork():
            os.wait()
        else:
            proc = psutil.Process()
            base = proc.memory_info().rss
            start = time.time()
            l = [func(x) for x in atoms]
            elapsed = time.time() - start
            size = humanize.naturalsize(proc.memory_info().rss - base)
            eprint(f"{impl:<20} {size:<10} {elapsed:.{2}f}s")
            os._exit(0)


if __name__ == "__main__":
    num_atoms = 1000000

    eprint(f"\nStatic atoms ({num_atoms})")
    test(("cat/pkg" for _ in range(num_atoms)))

    eprint(f"\nDynamic atoms ({num_atoms})")
    test((f"=cat/pkg-{x}-r1:2/3[a,b,c]" for x in range(num_atoms)))

    eprint(f"\nRandom atoms ({num_atoms})")
    test((f"=cat/pkg-{randrange(9999)}-r1:2/3[a,b,c]" for _ in range(num_atoms)))
