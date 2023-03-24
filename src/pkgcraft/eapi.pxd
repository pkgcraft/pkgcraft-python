from . cimport pkgcraft_c as C
from .error cimport _IndirectInit


cpdef Eapi eapi_from_obj(object obj)

cdef class Eapi(_IndirectInit):
    cdef const C.Eapi *ptr
    # cached fields
    cdef frozenset dep_keys
    cdef frozenset metadata_keys
    cdef str id
    cdef int hash

    @staticmethod
    cdef Eapi from_ptr(const C.Eapi *)
