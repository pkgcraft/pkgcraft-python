from .. cimport pkgcraft_c as C
from . cimport Repo


cdef class EbuildRepo(Repo):
    # cached fields
    cdef tuple _masters

    @staticmethod
    cdef EbuildRepo from_ptr(const C.Repo *, bint)
