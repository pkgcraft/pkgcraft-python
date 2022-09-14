from .. cimport pkgcraft_c as C

cdef class Pkg:
    cdef C.Pkg *_pkg
    # cached fields
    cdef int _hash
