from .. cimport C


cdef class Dependency:
    cdef C.Dependency *ptr
    cdef readonly object kind
    cdef readonly object set

    @staticmethod
    cdef Dependency from_ptr(C.Dependency *)


cdef class DependencySet:
    cdef C.DependencySet *ptr
    cdef readonly object set

    @staticmethod
    cdef DependencySet from_ptr(C.DependencySet *)

    cdef clone(self)
    cdef create(self, C.DependencySet *)

    @staticmethod
    cdef C.DependencySet *from_iter(object obj, C.DependencySetKind kind)


cdef class MutableDependencySet(DependencySet):

    @staticmethod
    cdef MutableDependencySet from_ptr(C.DependencySet *)
