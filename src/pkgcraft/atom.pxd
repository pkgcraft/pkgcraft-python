# SPDX-License-Identifier: MIT
# cython: language_level=3

from . cimport pkgcraft_c as C


cdef class Atom:
    cdef C.Atom *_atom
    cdef str _eapi

    # cached fields
    cdef str _category
    cdef str _package


cdef class Cpv(Atom):
    pass
