from .. cimport C


cdef class RepoSet:
    cdef C.RepoSet *ptr
    cdef bint immutable

    # cached fields
    cdef object _repos

    @staticmethod
    cdef RepoSet from_ptr(C.RepoSet *, bint immutable=*)


cdef class _Iter:
    cdef C.RepoSetIter *ptr
