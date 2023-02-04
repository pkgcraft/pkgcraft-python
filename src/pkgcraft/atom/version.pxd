from pkgcraft cimport pkgcraft_c as C


cdef class Version:
    cdef C.Version *ptr
    # cached fields
    cdef int _hash

    @staticmethod
    cdef Version from_ptr(C.Version *)


cdef class VersionWithOp(Version):
    pass
