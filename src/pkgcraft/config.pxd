from . cimport pkgcraft_c as C

cdef class Config:
    cdef C.Config *_config
    # cached fields
    cdef Repos _repos


cdef class Repos:
    # cached fields
    cdef dict _repos

    @staticmethod
    cdef Repos from_config(C.Config *)
