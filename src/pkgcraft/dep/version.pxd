from .. cimport C


cdef class Revision:
    cdef C.Revision *ptr
    # cached fields
    cdef int _hash

    @staticmethod
    cdef Revision from_ptr(C.Revision *)


cdef class Version:
    cdef C.Version *ptr
    # cached fields
    cdef int _hash
    cdef object _revision

    @staticmethod
    cdef Version from_ptr(C.Version *)
