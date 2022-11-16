from .. cimport pkgcraft_c as C


cdef class RepoSet:
    cdef C.RepoSet *_set
    cdef C.RepoSetPkgIter *_iter

    @staticmethod
    cdef RepoSet from_ptr(C.RepoSet *)


cdef class _RestrictIter:
    cdef C.RepoSetPkgIter *_iter

    @staticmethod
    cdef _RestrictIter create(RepoSet, object)
