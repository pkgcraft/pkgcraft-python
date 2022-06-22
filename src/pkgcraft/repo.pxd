# SPDX-License-Identifier: MIT
# cython: language_level=3

from . cimport pkgcraft_c as C

cdef class Repo:
    cdef C.Repo *_repo

    @staticmethod
    cdef Repo ref(const C.Repo *)
