from .. cimport pkgcraft_c as C
from . cimport Pkg

cdef class FakePkg(Pkg):
    @staticmethod
    cdef FakePkg from_ptr(C.Pkg *)
