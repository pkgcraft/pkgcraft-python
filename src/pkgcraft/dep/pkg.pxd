from .. cimport C
from ..eapi cimport Eapi


cdef class UseDep:
    cdef C.UseDep *ptr
    cdef readonly object kind
    cdef readonly object missing
    # cached fields
    cdef str _flag
    cdef int _hash

    @staticmethod
    cdef UseDep from_ptr(C.UseDep *)


cdef class Dep:
    cdef C.Dep *ptr
    cdef Eapi eapi
    # cached fields
    cdef object _blocker
    cdef str _category
    cdef str _package
    cdef object _version
    cdef object _slot
    cdef object _subslot
    cdef object _slot_op
    cdef object _use_deps
    cdef object _repo
    cdef int _hash

    # allow weak references
    cdef object __weakref__

    @staticmethod
    cdef Dep from_ptr(C.Dep *)


cdef class Cpn(Dep):
    pass
