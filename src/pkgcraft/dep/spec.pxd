from .. cimport pkgcraft_c as C
from ..error cimport _IndirectInit


cdef class DepSpec(_IndirectInit):
    cdef C.DepSpec *ptr

    @staticmethod
    cdef DepSpec from_ptr(C.DepSpec *)


cdef class Enabled(DepSpec):
    pass


cdef class Disabled(DepSpec):
    pass


cdef class AllOf(DepSpec):
    pass


cdef class AnyOf(DepSpec):
    pass


cdef class ExactlyOneOf(DepSpec):
    pass


cdef class AtMostOneOf(DepSpec):
    pass


cdef class UseDisabled(DepSpec):
    pass


cdef class UseEnabled(DepSpec):
    pass
