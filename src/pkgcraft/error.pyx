from . cimport pkgcraft_c as C


cdef class PkgcraftError(Exception):
    """Generic pkgcraft exception."""

    def __init__(self, str msg=None):
        cdef char *c_error = C.pkgcraft_last_error()
        cdef str error = None if c_error is NULL else c_error.decode()
        C.pkgcraft_str_free(c_error)

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


cdef class InvalidRestrict(PkgcraftError):
    """Object cannot be converted to a restriction."""
