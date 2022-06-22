# SPDX-License-Identifier: MIT
# cython: language_level=3

from .cpv cimport Cpv

include "../pkgcraft.pxi"

cdef class Atom(Cpv):
    cdef str _eapi
    # cached fields
    cdef object _use
