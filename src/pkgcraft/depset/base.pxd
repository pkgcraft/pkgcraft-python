from .. cimport pkgcraft_c as C
from ..error cimport _IndirectInit


cdef class DepSet(_IndirectInit):
    cdef C.DepSet *ptr
    cdef C.DepSetKind kind

    @staticmethod
    cdef DepSet from_ptr(C.DepSet *)


cdef class _IntoIter:
    cdef C.DepSetIntoIter *ptr
    cdef C.DepSetKind kind


cdef class _IntoIterFlatten:
    cdef C.DepSetIntoIterFlatten *ptr
    cdef C.DepSetKind kind


cdef class _IntoIterRecursive:
    cdef C.DepSetIntoIterRecursive *ptr
    cdef C.DepSetKind kind


cdef class Uri(_IndirectInit):
    cdef C.Uri *ptr
    # cached fields
    cdef str _uri_str

    @staticmethod
    cdef Uri from_ptr(C.Uri *)
