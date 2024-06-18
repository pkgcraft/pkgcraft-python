from .. cimport C


cdef class UseDep:
    cdef C.UseDep *ptr
    cdef readonly object kind
    cdef readonly str flag
    cdef object default_
    # cached fields
    cdef int _hash

    @staticmethod
    cdef UseDep from_ptr(C.UseDep *, UseDep inst=*)
