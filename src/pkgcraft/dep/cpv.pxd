from .. cimport C
from .version cimport Version


cdef class Cpv:
    cdef C.Cpv *ptr
    # cached fields
    cdef str _category
    cdef str _package
    cdef Version _version
    cdef int _hash

    @staticmethod
    cdef Cpv from_ptr(C.Cpv *)
