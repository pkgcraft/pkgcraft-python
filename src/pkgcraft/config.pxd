from . cimport C
from .error cimport _IndirectInit
from .repo cimport Repo, RepoSet


cdef dict repos_to_dict(C.Repo **, size_t, bint)

cdef class Config:
    cdef C.Config *ptr

    # cached fields
    cdef _Repos _repos

    cdef Repo add_repo_path(self, object, object, int, bint external=*)


cdef class _Repos(_IndirectInit):
    cdef C.Config *ptr

    # cached fields
    cdef dict _repos
    cdef RepoSet _all
    cdef RepoSet _ebuild

    @staticmethod
    cdef _Repos from_config(C.Config *)
