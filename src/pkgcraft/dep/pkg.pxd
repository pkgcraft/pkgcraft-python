from .. cimport C
from ..eapi cimport Eapi


cdef object _DEP_FIELDS

cdef class Dep:
    cdef C.Dep *ptr
    cdef Eapi eapi
    # cached fields
    cdef str _category
    cdef str _package
    cdef object _version
    cdef object _use_deps
    cdef int _hash

    # allow weak references
    cdef object __weakref__

    @staticmethod
    cdef Dep from_ptr(C.Dep *)


cdef class Cpn(Dep):
    pass
