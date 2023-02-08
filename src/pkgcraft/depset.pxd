from . cimport pkgcraft_c as C
from .error cimport _IndirectInit


cdef class DepRestrict(_IndirectInit):
    cdef C.DepRestrict *ptr
    cdef C.DepSetKind kind

    @staticmethod
    cdef DepRestrict from_ptr(C.DepRestrict *)


cdef class Enabled(DepRestrict):
    pass


cdef class Disabled(DepRestrict):
    pass


cdef class AllOf(DepRestrict):
    pass


cdef class AnyOf(DepRestrict):
    pass


cdef class ExactlyOneOf(DepRestrict):
    pass


cdef class AtMostOneOf(DepRestrict):
    pass


cdef class UseDisabled(DepRestrict):
    pass


cdef class UseEnabled(DepRestrict):
    pass


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
