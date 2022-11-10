from .. cimport pkgcraft_c as C
from . cimport Repo

cdef class FakeRepo(Repo):
    @staticmethod
    cdef FakeRepo from_ptr(const C.Repo *, bint)
