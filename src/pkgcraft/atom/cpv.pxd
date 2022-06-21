# SPDX-License-Identifier: MIT
# cython: language_level=3

from .. cimport pkgcraft_c as C


cdef class Cpv:
    cdef C.Atom *_atom
    # cached fields
    cdef str _category
    cdef str _package
    cdef object _version
