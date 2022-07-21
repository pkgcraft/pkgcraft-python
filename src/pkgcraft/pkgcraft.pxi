# Manual bindings for types that cbindgen currently mangles.

cdef extern from "pkgcraft.h":
    # Opaque wrapper for EbuildRepo objects.
    cdef struct EbuildRepo:
        pass

    # Opaque wrapper for EbuildPkg objects.
    cdef struct EbuildPkg:
        pass
