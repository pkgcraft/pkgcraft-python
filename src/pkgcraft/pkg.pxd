# SPDX-License-Identifier: MIT
# cython: language_level=3

from . cimport pkgcraft_c as C

cdef class Pkg:
    cdef C.Pkg *_pkg

    @staticmethod
    cdef Pkg create(C.Pkg *)
