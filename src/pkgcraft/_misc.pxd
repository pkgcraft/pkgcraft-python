from .error cimport Indirect


cdef object SENTINEL

cdef str cstring_to_str(char *ptr, bint free=*)
cdef object cstring_iter(char **c_strs, size_t length, bint free=*)


cdef class CStringArray:
    cdef char **ptr
    cdef list strs
