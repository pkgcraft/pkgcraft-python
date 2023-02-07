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


cdef class _IntoIter:
    cdef C.DepSetIntoIter *ptr
    cdef DepSetKind kind


cdef class _IntoIterFlatten:
    cdef C.DepSetIntoIterFlatten *ptr
    cdef DepSetKind kind


cdef class _IntoIterRecursive:
    cdef C.DepSetIntoIterRecursive *ptr
    cdef DepSetKind kind


cdef class Uri(_IndirectInit):
    cdef C.Uri *ptr
    # cached fields
    cdef str _uri_str

    @staticmethod
    cdef Uri from_ptr(C.Uri *)
