from .. cimport C
from ..pkg cimport Pkg


cdef class Repo:
    cdef C.Repo *ptr
    # flag denoting borrowed reference that must not be deallocated
    cdef bint ref

    # cached fields
    cdef str _id
    cdef object _path
    cdef int _hash

    @staticmethod
    cdef Repo from_ptr(C.Repo *, bint, Repo obj=*)


cdef class _Iter:
    cdef C.RepoIter *ptr


cdef class _IterRestrict:
    cdef C.RepoIterRestrict *ptr
