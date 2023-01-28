from .. cimport pkgcraft_c as C
from ..eapi cimport Eapi
from . cimport Repo


cdef class EbuildRepo(Repo):
    # cached fields
    cdef tuple _masters
