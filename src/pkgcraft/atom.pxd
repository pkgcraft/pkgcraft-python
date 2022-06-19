# SPDX-License-Identifier: MIT
# cython: language_level=3

from . cimport pkgcraft_c as C


cdef class Atom:
    cdef C.Atom *_atom
    cdef str _eapi


cdef class Cpv(Atom):
    pass
