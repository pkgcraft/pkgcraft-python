from . cimport pkgcraft_c as C

cdef int obj_to_restrict(object obj, C.Restrict **restrict) except -1

cdef class Restrict:
    cdef C.Restrict *_restrict

    @staticmethod
    cdef Restrict create(object)
