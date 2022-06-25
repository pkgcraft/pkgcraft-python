from .cpv cimport Cpv

include "../pkgcraft.pxi"

cdef class Atom(Cpv):
    # cached fields
    cdef object _use
