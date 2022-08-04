from . cimport pkgcraft_c as C
from .atom cimport Cpv
from .pkg cimport Pkg
from .error import PkgcraftError


cdef int obj_to_restrict(object obj, C.Restrict **restrict) except -1:
    """Convert an object to a restriction pointer."""
    cdef C.Restrict *r

    if isinstance(obj, Cpv):
        r = C.pkgcraft_atom_restrict((<Cpv>obj)._atom)
    elif isinstance(obj, Pkg):
        r = C.pkgcraft_pkg_restrict((<Pkg>obj)._pkg)
    elif isinstance(obj, str):
        r = C.pkgcraft_restrict_parse(obj.encode())
    else:
        raise TypeError(f"{obj.__class__.__name__!r} unsupported restriction type")

    if r is NULL:
        raise PkgcraftError

    restrict[0] = r
    return 0


cdef class Restrict:
    """Generic restriction."""

    def __init__(self, obj not None):
        obj_to_restrict(obj, &self._restrict)

    @staticmethod
    cdef Restrict create(object obj):
        r = <Restrict>Restrict.__new__(Restrict)
        obj_to_restrict(obj, &r._restrict)
        return r

    def __dealloc__(self):
        C.pkgcraft_restrict_free(self._restrict)
