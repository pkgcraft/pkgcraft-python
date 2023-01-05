from . cimport pkgcraft_c as C
from .error cimport _IndirectInit

ctypedef enum DepSetKind:
    DepSetAtom,
    DepSetString,
    DepSetUri


cdef class DepRestrict(_IndirectInit):
    cdef C.DepRestrict *ptr
    cdef DepSetKind kind

    @staticmethod
    cdef DepRestrict from_ptr(C.DepRestrict *, DepSetKind)


cdef class DepSet(_IndirectInit):
    cdef C.DepSet *ptr
    cdef DepSetKind kind

    @staticmethod
    cdef DepSet from_ptr(C.DepSet *, DepSetKind)


cdef class _Iter:
    cdef C.DepSetIter *ptr
    cdef DepSetKind kind


cdef class _IterFlatten:
    cdef C.DepSetFlattenIter *ptr
    cdef DepSetKind kind


cdef class Uri(_IndirectInit):
    cdef const C.Uri *ptr
    # cached fields
    cdef str _uri_str

    @staticmethod
    cdef Uri from_ptr(const C.Uri *)
