cimport cython

from . cimport Pkg
from ..error import IndirectInit


@cython.final
cdef class FakePkg(Pkg):
    """Generic fake package."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)
