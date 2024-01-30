from .. cimport C


cdef class Cpn:
    cdef C.Cpn *ptr
    # cached fields
    cdef str _category
    cdef str _package
    cdef int _hash

    @staticmethod
    cdef Cpn from_ptr(C.Cpn *)
