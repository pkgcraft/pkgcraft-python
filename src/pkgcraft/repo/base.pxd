from .. cimport pkgcraft_c as C
from ..error cimport _IndirectInit
from ..pkg cimport Pkg


cdef class Repo(_IndirectInit):
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


cdef class _Iter:
    cdef C.RepoPkgIter *ptr


cdef class _IterRestrict:
    cdef C.RepoRestrictPkgIter *ptr
