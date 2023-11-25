from .. cimport C
from ..dep cimport Cpv, Version
from ..eapi cimport Eapi
from ..error cimport Internal
from ..repo cimport Repo


cdef class Pkg(Internal):
    cdef C.Pkg *ptr

    # cached fields
    cdef Cpv _cpv
    cdef Version _version
    cdef Eapi _eapi
    cdef Repo _repo
    cdef int _hash

    @staticmethod
    cdef Pkg from_ptr(C.Pkg *)
