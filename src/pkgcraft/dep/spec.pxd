from .. cimport C
from ..error cimport _IndirectInit


cdef class DepSpec:
    cdef C.DepSpec *ptr
    cdef object kind
    cdef object set

    @staticmethod
    cdef DepSpec from_ptr(C.DepSpec *)


cdef class DepSet:
    cdef C.DepSet *ptr
    cdef object set

    @staticmethod
    cdef DepSet from_ptr(C.DepSet *)

    cdef clone(self)
    cdef create(self, C.DepSet *)

    @staticmethod
    cdef C.DepSet *from_iter(object obj, C.DepSetKind kind)


cdef class MutableDepSet(DepSet):

    @staticmethod
    cdef MutableDepSet from_ptr(C.DepSet *)


cdef class Uri(_IndirectInit):
    cdef C.Uri *ptr
    # cached fields
    cdef str _uri_str

    @staticmethod
    cdef Uri from_ptr(C.Uri *)
