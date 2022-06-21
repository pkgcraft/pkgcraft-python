# SPDX-License-Identifier: MIT
# cython: language_level=3

from .cpv cimport Cpv


cdef class Atom(Cpv):
    cdef str _eapi
    # cached fields
    cdef object _use
