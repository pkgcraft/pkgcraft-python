# SPDX-License-Identifier: MIT
# cython: language_level=3

from . cimport pkgcraft_c as C


cdef class PkgcraftError(Exception):
    """Generic pkgcraft exception."""

    cdef char *_error

    def __cinit__(self):
        self._error = C.pkgcraft_last_error()

    def __init__(self, str msg=None):
        if msg:
            super().__init__(msg)
        elif self._error:
            super().__init__(self._error.decode())
        else:
            raise RuntimeError("no error message passed and no C error occurred")

    def __dealloc__(self):
        C.pkgcraft_str_free(self._error)
