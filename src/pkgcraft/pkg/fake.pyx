cimport cython

from . cimport Pkg


@cython.final
cdef class FakePkg(Pkg):
    """Generic fake package."""
