cimport cython

from .. cimport C
from .._misc cimport cstring_to_str
from ..error cimport Indirect


@cython.final
cdef class Uri(Indirect):

    @staticmethod
    cdef Uri from_ptr(C.Uri *ptr):
        inst = <Uri>Uri.__new__(Uri)
        inst.ptr = ptr
        return inst

    @property
    def uri(self):
        if self._uri_str is None:
            self._uri_str = cstring_to_str(C.pkgcraft_uri_uri(self.ptr))
        return self._uri_str

    @property
    def filename(self):
        return cstring_to_str(C.pkgcraft_uri_filename(self.ptr))

    def __str__(self):
        return cstring_to_str(C.pkgcraft_uri_str(self.ptr))

    def __dealloc__(self):
        C.pkgcraft_uri_free(self.ptr)
