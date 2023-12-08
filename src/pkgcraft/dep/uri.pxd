from .. cimport C
from ..error cimport Indirect


cdef class Uri(Indirect):
    cdef C.Uri *ptr
    # cached fields
    cdef str _uri_str

    @staticmethod
    cdef Uri from_ptr(C.Uri *)
