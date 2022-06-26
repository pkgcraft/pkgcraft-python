from .. cimport pkgcraft_c as C
from ..pkg cimport Pkg

cdef class Repo:
    cdef C.Repo *_repo
    # flag denoting borrowed reference that must not be deallocated
    cdef bint _ref
    cdef C.PkgIter *_repo_iter

    @staticmethod
    cdef Repo from_ptr(const C.Repo *)
    @staticmethod
    cdef Repo from_ref(const C.Repo *)

    cdef Pkg create_pkg(self, C.Pkg *)
