from . cimport C
from .error cimport Internal


cdef class Eapi(Internal):
    cdef const C.Eapi *ptr
    # cached fields
    cdef object dep_keys
    cdef object metadata_keys
    cdef str id
    cdef int hash

    @staticmethod
    cdef Eapi from_ptr(const C.Eapi *, bint init=*)

    @staticmethod
    cdef Eapi _from_obj(object)
