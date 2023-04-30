cimport cython

from . cimport C
from .dep cimport Cpv, Dep
from .pkg cimport Pkg

from .error import InvalidCpv, InvalidDep, InvalidRestrict


cdef C.Restrict *str_to_restrict(str s) except NULL:
    """Try to convert a string to a Restrict pointer."""
    cdef C.Restrict *r

    try:
        return C.pkgcraft_cpv_restrict(Cpv(s).ptr)
    except InvalidCpv:
        pass

    try:
        return C.pkgcraft_dep_restrict(Dep(s).ptr)
    except InvalidDep:
        pass

    restrict_bytes = s.encode()
    r = C.pkgcraft_restrict_parse_dep(restrict_bytes)
    if r is NULL:
        r = C.pkgcraft_restrict_parse_pkg(restrict_bytes)
    if r is NULL:
        raise InvalidRestrict(f'invalid restriction string: {s}')

    return r


@cython.final
cdef class Restrict:
    """Generic restriction."""

    def __init__(self, obj not None):
        if isinstance(obj, Cpv):
            self.ptr = C.pkgcraft_cpv_restrict((<Cpv>obj).ptr)
        elif isinstance(obj, Dep):
            self.ptr = C.pkgcraft_dep_restrict((<Dep>obj).ptr)
        elif isinstance(obj, Pkg):
            self.ptr = C.pkgcraft_pkg_restrict((<Pkg>obj).ptr)
        elif isinstance(obj, str):
            self.ptr = str_to_restrict(obj)
        else:
            raise TypeError(f"{obj.__class__.__name__!r} unsupported restriction type")

    @staticmethod
    cdef Restrict from_ptr(C.Restrict *ptr):
        """Create a Restrict from a pointer."""
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

    def matches(self, obj not None):
        """Determine if a restriction matches a given object.

        Returns True if the restriction matches a given object, otherwise False.

        Raises TypeError for object types not supporting matches.
        """
        if isinstance(obj, Cpv):
            return C.pkgcraft_cpv_restrict_matches((<Cpv>obj).ptr, self.ptr)
        if isinstance(obj, Dep):
            return C.pkgcraft_dep_restrict_matches((<Dep>obj).ptr, self.ptr)
        elif isinstance(obj, Pkg):
            return C.pkgcraft_pkg_restrict_matches((<Pkg>obj).ptr, self.ptr)
        raise TypeError(f"{obj.__class__.__name__!r} unsupported restriction matches type")

    def __eq__(self, other):
        if isinstance(other, Restrict):
            return C.pkgcraft_restrict_eq(self.ptr, (<Restrict>other).ptr)
        return NotImplemented

    def __hash__(self):
        return C.pkgcraft_restrict_hash(self.ptr)

    def __and__(self, other):
        if isinstance(other, Restrict):
            ptr = C.pkgcraft_restrict_and(self.ptr, (<Restrict>other).ptr)
            return Restrict.from_ptr(ptr)
        return NotImplemented

    def __or__(self, other):
        if isinstance(other, Restrict):
            ptr = C.pkgcraft_restrict_or(self.ptr, (<Restrict>other).ptr)
            return Restrict.from_ptr(ptr)
        return NotImplemented

    def __xor__(self, other):
        if isinstance(other, Restrict):
            ptr = C.pkgcraft_restrict_xor(self.ptr, (<Restrict>other).ptr)
            return Restrict.from_ptr(ptr)
        return NotImplemented

    def __invert__(self):
        return Restrict.from_ptr(C.pkgcraft_restrict_not(self.ptr))

    def __dealloc__(self):
        C.pkgcraft_restrict_free(self.ptr)
