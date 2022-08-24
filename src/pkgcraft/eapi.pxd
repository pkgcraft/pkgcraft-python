from . cimport pkgcraft_c as C

cdef class Eapi:
    cdef const C.Eapi *_eapi
    cdef str id
