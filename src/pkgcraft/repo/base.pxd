from .. cimport pkgcraft_c as C
from ..pkg cimport Pkg

cdef class _RestrictIter:
    cdef Repo _repo
    cdef C.Restrict *_restrict
    cdef C.RestrictPkgIter *_iter

    @staticmethod
    cdef _RestrictIter create(Repo, object)

cdef class Repo:
    cdef C.Repo *_repo
    # flag denoting borrowed reference that must not be deallocated
    cdef bint _ref
    cdef C.PkgIter *_repo_iter

    # cached fields
    cdef str _id
    cdef str _path
    cdef int _hash

    cdef Pkg create_pkg(self, C.Pkg *)
