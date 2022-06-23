# SPDX-License-Identifier: MIT
# cython: language_level=3

from .. cimport pkgcraft_c as C

cdef class Repo:
    cdef C.Repo *_repo
    cdef C.PkgIter *_repo_iter

    @staticmethod
    cdef Repo from_ptr(const C.Repo *)
