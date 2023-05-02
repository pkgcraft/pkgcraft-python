cdef object SENTINEL

cdef str cstring_to_str(char *ptr, bint free=*)
cdef tuple cstring_array_to_tuple(char **c_strs, size_t length, bint free=*)

cdef class CStringArray:
    cdef char **ptr
    cdef list strs
