from .. cimport pkgcraft_c as C
from ..error cimport _IndirectInit


cdef class DepRestrict(_IndirectInit):
    cdef C.DepRestrict *ptr
    cdef C.DepSetUnit unit

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
