from .. cimport pkgcraft_c as C

cdef class Pkg:
    cdef C.Pkg *_pkg

    @staticmethod
    cdef Pkg create(C.Pkg *)
