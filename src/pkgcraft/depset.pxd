from . cimport pkgcraft_c as C


cdef class DepSet:
    cdef C.DepSet *_deps

    @staticmethod
    cdef DepSet from_ptr(C.DepSet *)
