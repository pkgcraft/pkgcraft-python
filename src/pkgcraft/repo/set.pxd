from .. cimport pkgcraft_c as C


cdef class RepoSet:
    cdef C.RepoSet *ptr
    cdef C.RepoSetPkgIter *iter_ptr

    @staticmethod
    cdef RepoSet from_ptr(C.RepoSet *)


cdef class _RestrictIter:
    cdef C.RepoSetPkgIter *ptr

    @staticmethod
    cdef _RestrictIter create(RepoSet, object)
