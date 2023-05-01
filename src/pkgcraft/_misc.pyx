from cpython.mem cimport PyMem_Free, PyMem_Malloc

from . cimport C

SENTINEL = object()

cdef str ptr_to_str(char *c_str, bint free=True):
    """Convert a char* to a string object, optionally freeing the pointer.

    Returns None if char* is NULL.
    """
    if c_str is not NULL:
        s = c_str.decode()
        if free:
            C.pkgcraft_str_free(c_str)
        return s
    return None


cdef tuple ptr_to_str_array(char **c_strs, size_t length, bint free=True):
    """Convert a char** to a tuple of strings, optional freeing the array.

    Returns None if char** is NULL.
    """
    if c_strs is not NULL:
        values = tuple(c_strs[i].decode() for i in range(length))
        if free:
            C.pkgcraft_str_array_free(c_strs, length)
        return values
    return None


cdef class StrArray:
    """Convert an iterable of stringable objects to an array of char*."""

    def __init__(self, object iterable):
        self.strs = [str(s).encode() for s in iterable]
        self.ptr = <char **>PyMem_Malloc(len(self.strs) * sizeof(char *))
        if not self.ptr:  # pragma: no cover
            raise MemoryError
        for i in range(len(self.strs)):
            self.ptr[i] = self.strs[i]

    def __len__(self):
        return len(self.strs)

    def __dealloc__(self):
        PyMem_Free(self.ptr)
