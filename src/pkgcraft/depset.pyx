from . cimport pkgcraft_c as C
from .atom cimport Cpv
from .pkg cimport Pkg
from .error import PkgcraftError


cdef class DepSet:
    """Dependency set of objects."""

    @staticmethod
    cdef DepSet from_ptr(C.DepSet *deps):
        obj = <DepSet>DepSet.__new__(DepSet)
        obj._deps = deps
        return obj

    def __str__(self):
        cdef char *c_str = C.pkgcraft_depset_str(self._deps)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __dealloc__(self):
        C.pkgcraft_depset_free(self._deps)
