from pkgcraft cimport pkgcraft_c as C

cdef class Version:
    cdef C.Version *_version
    # flag denoting borrowed reference that must not be deallocated
    cdef bint _ref

    @staticmethod
    cdef Version from_ref(const C.Version *)


cdef class VersionWithOp(Version):
    pass
