# Manual bindings for types that cbindgen currently mangles.

cdef extern from "pkgcraft.h":
    cpdef enum Blocker:
        NONE,
        Strong,
        Weak,
