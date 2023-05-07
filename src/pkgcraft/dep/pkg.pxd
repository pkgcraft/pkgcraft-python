from .. cimport C
from ..eapi cimport Eapi


cdef class Dep:
    cdef C.Dep *ptr
    cdef Eapi eapi
    # cached fields
    cdef str _category
    cdef str _package
    cdef object _version
    cdef object _use
    cdef int _hash

    @staticmethod
    cdef Dep from_ptr(C.Dep *)


cdef class Cpn(Dep):
    pass
