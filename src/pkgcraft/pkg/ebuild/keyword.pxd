from ... cimport C


cdef class Keyword:
    cdef C.Keyword *ptr
    cdef readonly str arch
    cdef readonly object status
    # cached fields
    cdef int _hash

    @staticmethod
    cdef Keyword from_ptr(C.Keyword *, Keyword inst=*)
