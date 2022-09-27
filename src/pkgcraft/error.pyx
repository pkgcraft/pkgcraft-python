from . cimport pkgcraft_c as C


cdef class PkgcraftError(Exception):
    """Generic pkgcraft exception."""

    def __init__(self, str msg=None):
        c_str = C.pkgcraft_last_error()
        error = None if c_str is NULL else c_str.decode()
        C.pkgcraft_str_free(c_str)

        if msg is not None:
            super().__init__(msg)
        elif error is not None:
            super().__init__(error)
        else:
            raise RuntimeError("no error message passed and no C error occurred")


cdef class InvalidCpv(PkgcraftError):
    """Package CPV doesn't meet required specifications."""


cdef class InvalidAtom(PkgcraftError):
    """Package atom doesn't meet required specifications."""


cdef class InvalidVersion(PkgcraftError):
    """Atom version doesn't meet required specifications."""


cdef class InvalidRestrict(PkgcraftError):
    """Object cannot be converted to a restriction."""


class IndirectInit(TypeError):
    """Object cannot be created directly via __init__()."""

    def __init__(self, obj):
        obj_name = obj.__class__.__name__
        super().__init__(f"{obj_name} objects cannot be created directly via __init__()")
