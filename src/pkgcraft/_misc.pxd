cdef object SENTINEL

cdef str ptr_to_str(char *ptr, bint free=*)
cdef tuple ptr_to_str_array(char **c_strs, size_t length, bint free=*)

cdef class StrArray:
    cdef char **ptr
    cdef list strs
