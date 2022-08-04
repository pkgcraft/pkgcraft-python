from . cimport pkgcraft_c as C
from .atom cimport Cpv
from .pkg cimport Pkg
from .error import PkgcraftError


cdef C.Restrict *obj_to_restrict(object obj) except NULL:
    """Convert an object to a restriction pointer."""
    cdef C.Restrict *r

    if isinstance(obj, Cpv):
        r = C.pkgcraft_atom_restrict((<Cpv>obj)._atom)
    elif isinstance(obj, Pkg):
        r = C.pkgcraft_pkg_restrict((<Pkg>obj)._pkg)
    elif isinstance(obj, str):
        r = C.pkgcraft_restrict_parse_dep(obj.encode())
    else:
        raise TypeError(f"{obj.__class__.__name__!r} unsupported restriction type")

    if r is NULL:
        raise PkgcraftError

    return r


cdef class Restrict:
    """Generic restriction."""

    def __init__(self, obj not None):
        self._restrict = obj_to_restrict(obj)

    @staticmethod
    cdef Restrict create(object obj):
        r = <Restrict>Restrict.__new__(Restrict)
        r._restrict = obj_to_restrict(obj)
        return r

    def __dealloc__(self):
        C.pkgcraft_restrict_free(self._restrict)
