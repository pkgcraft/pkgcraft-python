from . cimport pkgcraft_c as C

cdef class Eapi:
    cdef const C.Eapi *_eapi
    # cached fields
    cdef str _id
    cdef int _hash

    @staticmethod
    cdef Eapi from_ptr(const C.Eapi *, str)
