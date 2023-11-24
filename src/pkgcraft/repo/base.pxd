from .. cimport C


cdef class Repo:
    cdef C.Repo *ptr
    # flag denoting borrowed reference that must not be deallocated
    cdef bint ref

    # cached fields
    cdef str _id
    cdef object _path
    cdef int _hash

    @staticmethod
    cdef Repo from_ptr(C.Repo *, bint ref=*)
