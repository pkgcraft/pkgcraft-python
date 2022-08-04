from . cimport pkgcraft_c as C

cdef C.Restrict *obj_to_restrict(object obj) except NULL

cdef class Restrict:
    cdef C.Restrict *_restrict

    @staticmethod
    cdef Restrict create(object)
