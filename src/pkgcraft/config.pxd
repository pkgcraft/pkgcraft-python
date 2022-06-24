from . cimport pkgcraft_c as C

cdef class Config:
    cdef C.Config *_config
    # cached fields
    cdef object _repos
