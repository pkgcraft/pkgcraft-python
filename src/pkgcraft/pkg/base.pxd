from .. cimport pkgcraft_c as C

cdef class Pkg:
    cdef C.Pkg *_pkg
