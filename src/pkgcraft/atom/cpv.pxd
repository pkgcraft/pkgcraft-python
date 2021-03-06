from .. cimport pkgcraft_c as C


cdef class Cpv:
    cdef C.Atom *_atom
    # flag denoting borrowed reference that must not be deallocated
    cdef bint _ref
    # cached fields
    cdef str _category
    cdef str _package
    cdef object _version

    @staticmethod
    cdef Cpv from_ref(const C.Atom *)
