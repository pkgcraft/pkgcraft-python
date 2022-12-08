cimport cython

from .. cimport pkgcraft_c as C
from . cimport Pkg
from ..error import IndirectInit


@cython.final
cdef class FakePkg(Pkg):
    """Generic fake package."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    @staticmethod
    cdef FakePkg from_ptr(C.Pkg *ptr):
        """Create an instance from a Pkg pointer."""
        obj = <FakePkg>FakePkg.__new__(FakePkg)
        obj.ptr = <C.Pkg *>ptr
        return obj
