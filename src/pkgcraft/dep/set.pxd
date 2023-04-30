from .. cimport C
from ..error cimport _IndirectInit


cdef class DepSet(_IndirectInit):
    cdef C.DepSet *ptr

    @staticmethod
    cdef DepSet from_ptr(C.DepSet *, DepSet obj=*)


cdef class Dependencies(DepSet):
    pass


cdef class Restrict(DepSet):
    pass


cdef class RequiredUse(DepSet):
    pass


cdef class Properties(DepSet):
    pass


cdef class SrcUri(DepSet):
    pass


cdef class License(DepSet):
    pass


cdef class _IntoIter:
    cdef C.DepSpecIntoIter *ptr
    cdef C.DepSpecUnit unit


cdef class _IntoIterFlatten:
    cdef C.DepSpecIntoIterFlatten *ptr
    cdef C.DepSpecUnit unit


cdef class _IntoIterRecursive:
    cdef C.DepSpecIntoIterRecursive *ptr


cdef class Uri(_IndirectInit):
    cdef C.Uri *ptr
    # cached fields
    cdef str _uri_str

    @staticmethod
    cdef Uri from_ptr(C.Uri *)
