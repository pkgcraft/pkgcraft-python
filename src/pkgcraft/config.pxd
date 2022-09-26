from . cimport pkgcraft_c as C

cdef dict repos_to_dict(C.Repo **, size_t, bint)

cdef class Config:
    cdef C.Config *_config
    # cached fields
    cdef Repos _repos


cdef class Repos:
    cdef C.Config *_config
    # cached fields
    cdef dict _repos

    @staticmethod
    cdef Repos from_config(C.Config *)
