from .. cimport pkgcraft_c as C
from ..pkg cimport Pkg


cdef class Repo:
    cdef C.Repo *ptr
    # flag denoting borrowed reference that must not be deallocated
    cdef bint ref
    cdef C.RepoPkgIter *iter_ptr

    # cached fields
    cdef str _id
    cdef object _path
    cdef int _hash

    cdef inject_ptr(self, const C.Repo *, bint)
    cdef Pkg create_pkg(self, C.Pkg *)
    @staticmethod
    cdef Repo from_ptr(C.Repo *, bint)


cdef class _RestrictIter:
    cdef Repo repo
    cdef C.RepoRestrictPkgIter *ptr

    @staticmethod
    cdef _RestrictIter create(Repo, object)
