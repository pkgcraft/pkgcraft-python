cdef object SENTINEL

cdef str ptr_to_str(char *ptr, bint free=*)

cdef class StrArray:
    cdef char **ptr
    cdef list strs
