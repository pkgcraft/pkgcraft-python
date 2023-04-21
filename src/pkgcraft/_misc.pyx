from . cimport pkgcraft_c as C

SENTINEL = object()

cdef str ptr_to_str(char *c_str):
    """Convert a char* to a string object, freeing the pointer.

    Returns None if char* is NULL.
    """
    if c_str is not NULL:
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s
    return None
