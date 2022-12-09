from .. cimport pkgcraft_c as C


cdef class Cpv:
    cdef C.Atom *ptr
    # flag denoting borrowed reference that must not be deallocated
    cdef bint ref
    # cached fields
    cdef str _category
    cdef str _package
    cdef object _version
    cdef int _hash

    @staticmethod
    cdef Cpv from_ptr(const C.Atom *)


cdef class Atom(Cpv):
    # cached fields
    cdef object _use
