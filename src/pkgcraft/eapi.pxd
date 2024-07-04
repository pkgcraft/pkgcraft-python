from . cimport C
from .error cimport Indirect
from .types cimport OrderedFrozenSet


cpdef OrderedFrozenSet eapi_range(str)

cdef class Eapi(Indirect):
    cdef const C.Eapi *ptr
    # cached fields
    cdef OrderedFrozenSet dep_keys
    cdef OrderedFrozenSet metadata_keys
    cdef str _id
    cdef int _hash

    @staticmethod
    cdef Eapi from_ptr(const C.Eapi *)

    @staticmethod
    cdef Eapi _from_obj(object)
