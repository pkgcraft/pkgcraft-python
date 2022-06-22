# SPDX-License-Identifier: MIT
# cython: language_level=3

from pkgcraft cimport pkgcraft_c as C

cdef class Version:
    cdef C.Version *_version
    # flag denoting borrowed _version that shouldn't be deallocated
    cdef bint _ref

    @staticmethod
    cdef Version ref(const C.Version *)
