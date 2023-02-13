from .. cimport pkgcraft_c as C


cdef class RepoSet:
    cdef C.RepoSet *ptr

    # cached fields
    cdef object _repos

    @staticmethod
    cdef RepoSet from_ptr(C.RepoSet *)


cdef class _Iter:
    cdef C.RepoSetIter *ptr


cdef class _IterRestrict:
    cdef C.RepoSetIter *ptr
