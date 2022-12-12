from .. cimport pkgcraft_c as C
from ..pkg cimport Pkg


cdef class Repo:
    cdef C.Repo *ptr
    # flag denoting borrowed reference that must not be deallocated
    cdef bint ref

    # cached fields
    cdef str _id
    cdef object _path
    cdef int _hash

    cdef inject_ptr(self, const C.Repo *, bint)
    @staticmethod
    cdef Repo from_ptr(C.Repo *, bint)


cdef class _RepoIter:
    cdef C.RepoPkgIter *ptr


cdef class _RestrictIter:
    cdef C.RepoRestrictPkgIter *ptr
