from .. cimport pkgcraft_c as C
from ..error cimport _IndirectInit


cdef class DepSet(_IndirectInit):
    cdef C.DepSet *ptr
    cdef C.DepUnit unit

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
    cdef C.DepSetIntoIter *ptr
    cdef C.DepUnit unit


cdef class _IntoIterFlatten:
    cdef C.DepSetIntoIterFlatten *ptr
    cdef C.DepUnit unit


cdef class _IntoIterRecursive:
    cdef C.DepSetIntoIterRecursive *ptr
    cdef C.DepUnit unit


cdef class Uri(_IndirectInit):
    cdef C.Uri *ptr
    # cached fields
    cdef str _uri_str

    @staticmethod
    cdef Uri from_ptr(C.Uri *)
