cimport cython

from . cimport pkgcraft_c as C
from .dep cimport Cpv, Dep
from .pkg cimport Pkg

from .error import InvalidCpv, InvalidDep, InvalidRestrict


@cython.final
cdef class Restrict:
    """Generic restriction."""

    def __init__(self, obj not None):
        Restrict.from_obj(obj, self)

    @staticmethod
    cdef Restrict from_ptr(C.Restrict *ptr):
        """Create a Restrict from a pointer."""
        obj = <Restrict>Restrict.__new__(Restrict)
        obj.ptr = ptr
        return obj

    @staticmethod
    cdef Restrict from_obj(object obj, Restrict r=None):
        """Try to convert an object to a Restrict."""
        if r is None:
            r = <Restrict>Restrict.__new__(Restrict)

        if isinstance(obj, Cpv):
            r.ptr = C.pkgcraft_cpv_restrict((<Cpv>obj).ptr)
        elif isinstance(obj, Dep):
            r.ptr = C.pkgcraft_dep_restrict((<Dep>obj).ptr)
        elif isinstance(obj, Pkg):
            r.ptr = C.pkgcraft_pkg_restrict((<Pkg>obj).ptr)
        elif isinstance(obj, str):
            Restrict.from_str(obj, r)
        else:
            raise TypeError(f"{obj.__class__.__name__!r} unsupported restriction type")

        return r

    @staticmethod
    cdef Restrict from_str(str s, Restrict r=None):
        """Try to convert a string to a Restrict."""
        cdef C.Restrict *ptr = NULL

        if r is None:
            r = <Restrict>Restrict.__new__(Restrict)

        try:
            ptr = C.pkgcraft_cpv_restrict(Cpv(s).ptr)
        except InvalidCpv:
            pass

        if ptr is NULL:
            try:
                ptr = C.pkgcraft_dep_restrict(Dep(s).ptr)
            except InvalidDep:
                pass

        restrict_bytes = s.encode()
        if ptr is NULL:
            ptr = C.pkgcraft_restrict_parse_dep(restrict_bytes)
        if ptr is NULL:
            ptr = C.pkgcraft_restrict_parse_pkg(restrict_bytes)
        if ptr is NULL:
            raise InvalidRestrict(f'invalid restriction string: {s}')

        r.ptr = ptr
        return r

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
