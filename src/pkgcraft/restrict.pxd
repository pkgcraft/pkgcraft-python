from . cimport pkgcraft_c as C


cdef class Restrict:
    cdef C.Restrict *ptr

    @staticmethod
    cdef Restrict from_ptr(C.Restrict *)

    @staticmethod
    cdef Restrict from_obj(object, Restrict r=*)

    @staticmethod
    cdef Restrict from_str(str, Restrict r=*)
