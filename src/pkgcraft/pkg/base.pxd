from .. cimport C
from ..dep cimport Cpv, Version
from ..eapi cimport Eapi
from ..error cimport _IndirectInit


cdef class Pkg(_IndirectInit):
    cdef C.Pkg *ptr

    # cached fields
    cdef Cpv _cpv
    cdef Eapi _eapi
    cdef Version _version
    cdef int _hash

    @staticmethod
    cdef Pkg from_ptr(C.Pkg *)
