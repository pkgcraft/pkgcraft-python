from .. cimport pkgcraft_c as C


cdef class Cpv:
    cdef C.Atom *ptr
    # cached fields
    cdef str _category
    cdef str _package
    cdef object _version
    cdef int _hash

    @staticmethod
    cdef Cpv from_ptr(C.Atom *)


cdef class Atom(Cpv):
    # cached fields
    cdef object _use

    @staticmethod
    cdef Atom from_ptr(C.Atom *)
