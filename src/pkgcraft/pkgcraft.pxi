# SPDX-License-Identifier: MIT
# cython: language_level=3
# Manual bindings for types that cbindgen currently mangles.

cdef extern from "pkgcraft.h":
    cpdef enum Blocker:
        NONE,
        Strong,
        Weak,
