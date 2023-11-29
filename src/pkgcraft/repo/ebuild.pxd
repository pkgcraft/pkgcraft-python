from .. cimport C
from ..eapi cimport Eapi
from ..error cimport Indirect
from ..types cimport OrderedFrozenSet
from . cimport Repo


cdef class EbuildRepo(Repo):
    # cached fields
    cdef Eapi _eapi
    cdef tuple _masters
    cdef OrderedFrozenSet _licenses
    cdef Metadata _metadata


cdef class Metadata(Indirect):
    cdef C.Repo *ptr
    # cached fields
    cdef OrderedFrozenSet _arches
    cdef OrderedFrozenSet _categories
    cdef OrderedFrozenSet _licenses

    @staticmethod
    cdef Metadata from_ptr(C.Repo *)


cdef class ConfiguredRepo(EbuildRepo):
    pass
