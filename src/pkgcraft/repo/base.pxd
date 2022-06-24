from .. cimport pkgcraft_c as C

cdef class Repo:
    cdef C.Repo *_repo
    # flag denoting borrowed reference that must not be deallocated
    cdef bint _ref
    cdef C.PkgIter *_repo_iter

    @staticmethod
    cdef Repo from_ptr(C.Repo *)
    @staticmethod
    cdef Repo from_ref(C.Repo *)
