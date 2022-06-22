# SPDX-License-Identifier: MIT
# cython: language_level=3

from . cimport pkgcraft_c as C
from .atom cimport Cpv
from .error import PkgcraftError


cdef class Pkg:
    """Generic package."""

    def __init__(self):
        raise PkgcraftError(f"{self.__class__} doesn't support regular creation")

    @staticmethod
    cdef Pkg create(C.Pkg *pkg):
        # create instance without calling __init__()
        obj = <Pkg>Pkg.__new__(Pkg)
        obj._pkg = <C.Pkg *>pkg
        return obj

    @property
    def atom(self):
        """Get a package's atom."""
        cdef const C.Atom *cpv = C.pkgcraft_pkg_atom(self._pkg)
        return Cpv.ref(cpv)

    def __repr__(self):
        cdef size_t addr = <size_t>&self._pkg
        name = self.__class__.__name__
        return f"<{name} '{self.atom}' at 0x{addr:0x}>"

    def __dealloc__(self):
        C.pkgcraft_pkg_free(self._pkg)
