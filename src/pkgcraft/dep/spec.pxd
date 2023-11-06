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

    cdef create(self, C.DepSet *)

    @staticmethod
    cdef C.DepSet *from_iter(object obj, C.DepSetKind kind)


cdef class MutableDepSet(DepSet):

    @staticmethod
    cdef MutableDepSet from_ptr(C.DepSet *)


cdef class _IntoIter:
    cdef C.DepSpecIntoIter *ptr


cdef class _IntoIterReversed(_IntoIter):
    pass


cdef class _IntoIterConditionals:
    cdef C.DepSpecIntoIterConditionals *ptr


cdef class _IntoIterFlatten:
    cdef C.DepSpecIntoIterFlatten *ptr
    cdef C.DepSetKind set


cdef class _IntoIterRecursive:
    cdef C.DepSpecIntoIterRecursive *ptr


cdef class Uri(_IndirectInit):
    cdef C.Uri *ptr
    # cached fields
    cdef str _uri_str

    @staticmethod
    cdef Uri from_ptr(C.Uri *)
