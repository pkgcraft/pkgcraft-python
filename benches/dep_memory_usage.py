# Script to roughly benchmark memory usage for package dependency object
# instances between pkgcraft, pkgcore, and portage.

import os
import sys
import time
from random import randrange

import humanize
import psutil
from pkgcore.ebuild.atom import atom as pkgcore_dep
from portage.dep import Atom as portage_dep

from pkgcraft.dep import Dep as pkgcraft_dep

eprint = lambda x: print(x, file=sys.stderr)

dep_funcs = [
    ("pkgcraft", pkgcraft_dep),
    ("pkgcraft-cached", pkgcraft_dep.cached),
    ("pkgcore", pkgcore_dep),
    ("portage", portage_dep),
]


def test(deps):
    eprint("---------------------------------------")
    eprint("{:<20} {:<10} time".format("implementation", "memory"))
    eprint("---------------------------------------")
    for impl, func in dep_funcs:
        if _pid := os.fork():
            os.wait()
        else:
            proc = psutil.Process()
            base = proc.memory_info().rss
            start = time.time()
            _deps = [func(x) for x in deps]
            elapsed = time.time() - start
            size = humanize.naturalsize(proc.memory_info().rss - base)
            eprint(f"{impl:<20} {size:<10} {elapsed:.{2}f}s")
            os._exit(0)


if __name__ == "__main__":
    num_deps = 1000000

    eprint(f"\nStatic deps ({num_deps})")
    test(("cat/pkg" for _ in range(num_deps)))

    eprint(f"\nDynamic deps ({num_deps})")
    test((f"=cat/pkg-{x}-r1:2/3[a,b,c]" for x in range(num_deps)))

    eprint(f"\nRandom deps ({num_deps})")
    test((f"=cat/pkg-{randrange(9999)}-r1:2/3[a,b,c]" for _ in range(num_deps)))
