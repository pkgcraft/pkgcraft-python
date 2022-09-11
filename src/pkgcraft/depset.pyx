from . cimport pkgcraft_c as C
from .atom cimport Cpv
from .pkg cimport Pkg
from .error import PkgcraftError


cdef class DepSetAtom:
    """Dependency set of atom objects."""

    @staticmethod
    cdef DepSetAtom from_ptr(const C.DepSetAtom *deps):
        obj = <DepSetAtom>DepSetAtom.__new__(DepSetAtom)
        obj._deps = deps
        return obj

    def __str__(self):
        cdef char *c_str = C.pkgcraft_depset_atom_str(self._deps)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s


cdef class DepSetString:
    """Dependency set of string objects."""

    @staticmethod
    cdef DepSetString from_ptr(const C.DepSetString *deps):
        obj = <DepSetString>DepSetString.__new__(DepSetString)
        obj._deps = deps
        return obj

    def __str__(self):
        cdef char *c_str = C.pkgcraft_depset_string_str(self._deps)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s


cdef class DepSetUri:
    """Dependency set of URI objects."""

    @staticmethod
    cdef DepSetUri from_ptr(const C.DepSetUri *deps):
        obj = <DepSetUri>DepSetUri.__new__(DepSetUri)
        obj._deps = deps
        return obj

    def __str__(self):
        cdef char *c_str = C.pkgcraft_depset_uri_str(self._deps)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s
