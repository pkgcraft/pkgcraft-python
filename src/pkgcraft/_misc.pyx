from cpython.mem cimport PyMem_Free, PyMem_Malloc

from . cimport C
from .error cimport _IndirectInit

SENTINEL = object()

cdef str cstring_to_str(char *c_str, bint free=True):
    """Convert a char* to a string object, optionally freeing the pointer.

    Returns None if char* is NULL.
    """
    if c_str is not NULL:
        s = c_str.decode()
        if free:
            C.pkgcraft_str_free(c_str)
        return s
    return None


cdef class CStringIter(_IndirectInit):
    """Iterator over a char** converting char* to str, optionally freeing the array."""

    @staticmethod
    cdef CStringIter create(char **c_strs, size_t length, bint free=True):
        obj = <CStringIter>CStringIter.__new__(CStringIter)
        obj.c_strs = c_strs
        obj.length = length
        obj.free = free
        obj.idx = 0
        return obj

    def __iter__(self):
        return self

    def __next__(self):
        if self.c_strs is not NULL and self.idx < self.length:
            s = self.c_strs[self.idx].decode()
            self.idx += 1
            return s
        raise StopIteration

    def __dealloc__(self):
        if self.free:
            C.pkgcraft_str_array_free(self.c_strs, self.length)


cdef class CStringArray:
    """Convert an iterable of stringable objects to an array of char*.

    Note that this copies the strings to byte objects in order to avoid scope
    issues when the array is freed automatically on instance deallocation.
    """
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
