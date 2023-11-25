from ..eapi cimport Eapi
from . cimport Repo


cdef class EbuildRepo(Repo):
    # cached fields
    cdef Eapi _eapi
    cdef tuple _masters
    cdef object _metadata
