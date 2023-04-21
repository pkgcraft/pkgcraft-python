cdef object SENTINEL

cdef str ptr_to_str(char *ptr)

cdef class StrArray:
    cdef char **ptr
    cdef list strs
    cdef int len
