# SPDX-License-Identifier: MIT
# cython: language_level=3

from . cimport pkgcraft_c as C

cdef class Version:
    cdef C.Version *_version

    @staticmethod
    cdef Version borrowed(const C.Version *)
