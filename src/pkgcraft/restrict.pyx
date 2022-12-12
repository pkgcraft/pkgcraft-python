cimport cython

from . cimport pkgcraft_c as C
from .atom cimport Atom, Cpv
from .pkg cimport Pkg

from .error import InvalidAtom, InvalidCpv, InvalidRestrict


cdef C.Restrict *str_to_restrict(str s) except NULL:
    """Try to convert a string to a restriction pointer."""
    cdef C.Restrict *r

    try:
        return C.pkgcraft_atom_restrict(Cpv(s).ptr)
    except InvalidCpv:
        pass

    try:
        return C.pkgcraft_atom_restrict(Atom(s).ptr)
    except InvalidAtom:
        pass

    restrict_bytes = s.encode()
    r = C.pkgcraft_restrict_parse_dep(restrict_bytes)
    if r is NULL:
        r = C.pkgcraft_restrict_parse_pkg(restrict_bytes)
    if r is NULL:
        raise InvalidRestrict(f'invalid restriction string: {s}')

    return r


cdef C.Restrict *obj_to_restrict(object obj) except NULL:
    """Try to convert an object to a restriction pointer."""
    if isinstance(obj, Cpv):
        return C.pkgcraft_atom_restrict((<Cpv>obj).ptr)
    elif isinstance(obj, Pkg):
        return C.pkgcraft_pkg_restrict((<Pkg>obj).ptr)
    elif isinstance(obj, str):
        return str_to_restrict(obj)
    else:
        raise TypeError(f"{obj.__class__.__name__!r} unsupported restriction type")


@cython.final
cdef class Restrict:
    """Generic restriction."""

    def __init__(self, obj):
        self.ptr = obj_to_restrict(obj)

    @staticmethod
    cdef Restrict from_ptr(C.Restrict *ptr):
        obj = <Restrict>Restrict.__new__(Restrict)
        obj.ptr = ptr
        return obj

    @staticmethod
    def dep(str s not None):
        """Convert a string into a dependency-based restriction."""
        ptr = C.pkgcraft_restrict_parse_dep(s.encode())
        if ptr is NULL:
            raise InvalidRestrict
        return Restrict.from_ptr(ptr)

    @staticmethod
    def pkg(str s not None):
        """Convert a string into a package-based restriction."""
        ptr = C.pkgcraft_restrict_parse_pkg(s.encode())
        if ptr is NULL:
            raise InvalidRestrict
        return Restrict.from_ptr(ptr)

    def matches(self, obj):
        """Determine if a restriction matches a given object.

        Returns True if the restriction matches a given object, otherwise False.

        Raises TypeError for object types not supporting matches.
        """
        if isinstance(obj, Cpv):
            return C.pkgcraft_atom_restrict_matches((<Cpv>obj).ptr, self.ptr)
        elif isinstance(obj, Pkg):
            return C.pkgcraft_pkg_restrict_matches((<Pkg>obj).ptr, self.ptr)
        raise TypeError(f"{obj.__class__.__name__!r} unsupported restriction matches type")

    def __eq__(self, Restrict other):
        return C.pkgcraft_restrict_eq(self.ptr, other.ptr)

    def __hash__(self):
        return C.pkgcraft_restrict_hash(self.ptr)

    def __and__(Restrict self, Restrict other):
        return Restrict.from_ptr(C.pkgcraft_restrict_and(self.ptr, other.ptr))

    def __or__(Restrict self, Restrict other):
        return Restrict.from_ptr(C.pkgcraft_restrict_or(self.ptr, other.ptr))

    def __xor__(Restrict self, Restrict other):
        return Restrict.from_ptr(C.pkgcraft_restrict_xor(self.ptr, other.ptr))

    def __invert__(Restrict self):
        return Restrict.from_ptr(C.pkgcraft_restrict_not(self.ptr))

    def __dealloc__(self):
        C.pkgcraft_restrict_free(self.ptr)
