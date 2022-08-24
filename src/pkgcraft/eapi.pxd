from . cimport pkgcraft_c as C

cdef class Eapi:
    cdef const C.Eapi *_eapi
    # cached fields
    cdef str _id

    @staticmethod
    cdef Eapi from_ptr(const C.Eapi *)
