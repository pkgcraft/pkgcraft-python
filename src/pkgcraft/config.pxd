from . cimport C
from .repo cimport Repo


cdef dict repos_to_dict(C.Repo **, size_t, bint)

cdef class Config:
    cdef C.Config *ptr

    # cached fields
    cdef object _repos

    cdef Repo add_repo_path(self, object, object, int, bint external=*)
