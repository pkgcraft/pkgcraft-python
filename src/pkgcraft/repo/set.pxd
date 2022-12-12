from .. cimport pkgcraft_c as C


cdef class RepoSet:
    cdef C.RepoSet *ptr

    @staticmethod
    cdef RepoSet from_ptr(C.RepoSet *)


cdef class _RepoSetIter:
    cdef C.RepoSetPkgIter *ptr


cdef class _RestrictIter:
    cdef C.RepoSetPkgIter *ptr
