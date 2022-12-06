from pkgcraft cimport pkgcraft_c as C


cdef class Version:
    cdef C.AtomVersion *ptr
    # flag denoting borrowed reference that must not be deallocated
    cdef bint ref
    # cached fields
    cdef int _hash

    @staticmethod
    cdef Version from_ptr(const C.AtomVersion *)


cdef class VersionWithOp(Version):
    pass
