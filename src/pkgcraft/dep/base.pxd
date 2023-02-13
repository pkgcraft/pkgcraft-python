from .. cimport pkgcraft_c as C
from ..error cimport _IndirectInit


cdef class Dep(_IndirectInit):
    cdef C.Dep *ptr

    @staticmethod
    cdef Dep from_ptr(C.Dep *)


cdef class Enabled(Dep):
    pass


cdef class Disabled(Dep):
    pass


cdef class AllOf(Dep):
    pass


cdef class AnyOf(Dep):
    pass


cdef class ExactlyOneOf(Dep):
    pass


cdef class AtMostOneOf(Dep):
    pass


cdef class UseDisabled(Dep):
    pass


cdef class UseEnabled(Dep):
    pass
