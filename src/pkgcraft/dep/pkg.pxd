from .. cimport pkgcraft_c as C


cdef class Cpv:
    cdef C.PkgDep *ptr
    # cached fields
    cdef str _category
    cdef str _package
    cdef object _version
    cdef int _hash

    @staticmethod
    cdef Cpv from_ptr(C.PkgDep *)


cdef class PkgDep(Cpv):
    # cached fields
    cdef object _use

    @staticmethod
    cdef PkgDep from_ptr(C.PkgDep *)
