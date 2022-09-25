from .. cimport pkgcraft_c as C


cdef class RepoSet:
    cdef C.RepoSet *_repo_set
    cdef C.RepoSetPkgIter *_iter


cdef class _RestrictIter:
    cdef C.RepoSetRestrictPkgIter *_iter

    @staticmethod
    cdef _RestrictIter create(RepoSet, object)
