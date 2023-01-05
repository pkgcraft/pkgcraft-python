from . cimport pkgcraft_c as C
from .error cimport _IndirectInit


cdef class Eapi(_IndirectInit):
    cdef const C.Eapi *ptr
    # cached fields
    cdef frozenset _dep_keys
    cdef frozenset _metadata_keys
    cdef str _id
    cdef int _hash

    @staticmethod
    cdef Eapi from_ptr(const C.Eapi *, str)
