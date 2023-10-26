from .. cimport C
from ..error cimport _IndirectInit


cdef class DepSpec(_IndirectInit):
    cdef C.DepSpec *ptr
    cdef readonly object kind

    @staticmethod
    cdef DepSpec from_ptr(C.DepSpec *)
