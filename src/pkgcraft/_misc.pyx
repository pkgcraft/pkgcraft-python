from functools import lru_cache
from weakref import WeakValueDictionary

cimport cython
from cpython.mem cimport PyMem_Free, PyMem_Malloc

from . cimport C
from .error cimport Indirect

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


cdef object cstring_iter(char **c_strs, size_t length, bint free=True):
    """Convert a char** array to an iterator of strings."""
    return CStringIter.create(c_strs, length, free)


@cython.internal
cdef class CStringIter(Indirect):
    """Iterator over a char** converting char* to str, optionally freeing the array."""

    cdef char **c_strs
    cdef size_t length
    cdef bint free
    cdef size_t idx

    @staticmethod
    cdef CStringIter create(char **c_strs, size_t length, bint free=True):
        inst = <CStringIter>CStringIter.__new__(CStringIter)
        inst.c_strs = c_strs
        inst.length = length
        inst.free = free
        inst.idx = 0
        return inst

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


class WeakInstanceCache(type):
    """Metaclass providing weakref-based instance caching."""

    def __new__(cls, name, bases, attrs):
        attrs["__slots__"] = ()
        attrs["__weak_instance_cache__"] = WeakValueDictionary()
        return super().__new__(cls, name, bases, attrs)

    def __call__(cls, *args, **kwargs):
        key = (args, tuple(sorted(kwargs.items())))
        instance = cls.__weak_instance_cache__.get(key)
        if instance is None:
            instance = super(WeakInstanceCache, cls).__call__(*args, **kwargs)
            cls.__weak_instance_cache__[key] = instance
        return instance


class LruInstanceCache(type):
    """Metaclass providing LRU-based instance caching.

    Note that this currently doesn't provide any cache key customization so
    attributes such as kwargs ordering will affect cache hits.
    """

    def __new__(cls, name, bases, attrs):
        attrs["__slots__"] = ()
        return super().__new__(cls, name, bases, attrs)

    @lru_cache(maxsize=10000)
    def __call__(cls, *args, **kwargs):
        return super(LruInstanceCache, cls).__call__(*args, **kwargs)
