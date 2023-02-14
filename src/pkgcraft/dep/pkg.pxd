from .. cimport pkgcraft_c as C


cdef class Cpv:
    cdef C.Dep *ptr
    # cached fields
    cdef str _category
    cdef str _package
    cdef object _version
    cdef int _hash

    @staticmethod
    cdef Cpv from_ptr(C.Dep *)


cdef class Dep(Cpv):
    # cached fields
    cdef object _use

    @staticmethod
    cdef Dep from_ptr(C.Dep *)
