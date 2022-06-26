# Manual bindings for types that cbindgen currently mangles.

cdef extern from "pkgcraft.h":
    cpdef enum Blocker:
        NONE,
        Strong,
        Weak,

    # Opaque wrapper for EbuildRepo objects.
    cdef struct EbuildRepo:
        pass

    # Opaque wrapper for EbuildPkg objects.
    cdef struct EbuildPkg:
        pass
