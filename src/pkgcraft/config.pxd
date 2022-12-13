from . cimport pkgcraft_c as C
from .repo cimport RepoSet


cdef dict repos_to_dict(C.Repo **, size_t, bint)

cdef class Config:
    cdef C.Config *ptr

    # cached fields
    cdef Repos _repos

    cdef C.Repo *_add_repo_path(self, object, object, int) except NULL


cdef class Repos:
    cdef C.Config *config_ptr

    # cached fields
    cdef dict _repos
    cdef RepoSet _all
    cdef RepoSet _ebuild

    @staticmethod
    cdef Repos from_config(C.Config *)
