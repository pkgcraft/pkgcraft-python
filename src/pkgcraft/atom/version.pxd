from pkgcraft cimport pkgcraft_c as C


cdef class Version:
    cdef C.AtomVersion *ptr
    # cached fields
    cdef int _hash

    @staticmethod
    cdef Version from_ptr(C.AtomVersion *)


cdef class VersionWithOp(Version):
    pass
