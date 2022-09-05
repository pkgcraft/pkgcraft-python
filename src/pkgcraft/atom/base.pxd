from .cpv cimport Cpv


cdef class Atom(Cpv):
    # cached fields
    cdef object _use
