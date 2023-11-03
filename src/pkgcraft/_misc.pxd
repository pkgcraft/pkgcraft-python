from .error cimport _IndirectInit


cdef object SENTINEL

cdef str cstring_to_str(char *ptr, bint free=*)


cdef class CStringIter(_IndirectInit):
    cdef char **c_strs
    cdef size_t length
    cdef bint free
    cdef size_t idx

    @staticmethod
    cdef CStringIter create(char **c_strs, size_t length, bint free=*)


cdef class CStringArray:
    cdef char **ptr
    cdef list strs
