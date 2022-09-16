from . cimport pkgcraft_c as C
from .atom cimport Atom, Cpv
from .pkg cimport Pkg
from .error import InvalidCpv, InvalidAtom, InvalidRestrict, PkgcraftError


cdef C.Restrict *str_to_restrict(str s) except NULL:
    """Try to convert a string to a restriction pointer."""
    cdef C.Restrict *r

    try:
        return C.pkgcraft_atom_restrict(Cpv(s)._atom)
    except InvalidCpv:
        pass

    try:
        return C.pkgcraft_atom_restrict(Atom(s)._atom)
    except InvalidAtom:
        pass

    restrict_bytes = s.encode()
    r = C.pkgcraft_restrict_parse_dep(restrict_bytes)
    if r is NULL:
        r = C.pkgcraft_restrict_parse_pkg(restrict_bytes)
    if r is NULL:
        raise InvalidRestrict(f'invalid restriction string: {s!r}')

    return r


cdef C.Restrict *obj_to_restrict(object obj) except NULL:
    """Try to convert an object to a restriction pointer."""
    if isinstance(obj, Cpv):
        return C.pkgcraft_atom_restrict((<Cpv>obj)._atom)
    elif isinstance(obj, Pkg):
        return C.pkgcraft_pkg_restrict((<Pkg>obj)._pkg)
    elif isinstance(obj, str):
        return str_to_restrict(obj)
    else:
        raise TypeError(f"{obj.__class__.__name__!r} unsupported restriction type")


cdef class Restrict:
    """Generic restriction."""

    def __init__(self, obj not None):
        self._restrict = obj_to_restrict(obj)

    def __and__(Restrict self, Restrict other):
        obj = <Restrict>Restrict.__new__(Restrict)
        obj._restrict = C.pkgcraft_restrict_and(self._restrict, other._restrict)
        return obj

    def __or__(Restrict self, Restrict other):
        obj = <Restrict>Restrict.__new__(Restrict)
        obj._restrict = C.pkgcraft_restrict_or(self._restrict, other._restrict)
        return obj

    def __xor__(Restrict self, Restrict other):
        obj = <Restrict>Restrict.__new__(Restrict)
        obj._restrict = C.pkgcraft_restrict_xor(self._restrict, other._restrict)
        return obj

    def __invert__(Restrict self):
        obj = <Restrict>Restrict.__new__(Restrict)
        obj._restrict = C.pkgcraft_restrict_not(self._restrict)
        return obj

    def __dealloc__(self):
        C.pkgcraft_restrict_free(self._restrict)
