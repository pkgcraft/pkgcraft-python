from .. cimport pkgcraft_c as C
from ..error cimport IndirectInit


cdef class Pkg(IndirectInit):
    cdef C.Pkg *ptr
    # cached fields
    cdef int _hash

    @staticmethod
    cdef Pkg from_ptr(C.Pkg *)
