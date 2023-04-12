from . cimport pkgcraft_c as C


cdef C.Restrict *str_to_restrict(str s) except NULL

cdef class Restrict:
    cdef C.Restrict *ptr

    @staticmethod
    cdef Restrict from_ptr(C.Restrict *)
