from .. cimport C
from ..eapi cimport Eapi
from ..error cimport _IndirectInit
from . cimport Repo


cdef class EbuildRepo(Repo):
    # cached fields
    cdef Eapi _eapi
    cdef tuple _masters
    cdef _Metadata _metadata


cdef class _Metadata(_IndirectInit):
    cdef C.Repo *ptr

    # cached fields
    cdef object _arches
    cdef object _categories

    @staticmethod
    cdef _Metadata from_ptr(C.Repo *)
