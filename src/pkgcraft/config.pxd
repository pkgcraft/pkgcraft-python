from . cimport pkgcraft_c as C

cdef dict repos_to_dict(C.Repo **, size_t, bint)

cdef class Config:
    cdef C.Config *_config
    # cached fields
    cdef Repos _repos

    cdef C.Repo *_add_repo_path(self, object, object, int) except NULL


cdef class Repos:
    cdef C.Config *_config
    # cached fields
    cdef dict _repos
    cdef object _all_repos
    cdef object _ebuild_repos

    @staticmethod
    cdef Repos from_config(C.Config *)
