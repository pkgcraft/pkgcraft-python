from .. cimport C


cdef class Cpv:
    cdef C.Cpv *ptr
    # cached fields
    cdef str _category
    cdef str _package
    cdef object _version
    cdef int _hash

    @staticmethod
    cdef Cpv from_ptr(C.Cpv *)
