from .. cimport pkgcraft_c as C


cdef class Dep:
    cdef C.Dep *ptr
    # cached fields
    cdef str _category
    cdef str _package
    cdef object _version
    cdef object _use
    cdef int _hash

    @staticmethod
    cdef Dep from_ptr(C.Dep *)
