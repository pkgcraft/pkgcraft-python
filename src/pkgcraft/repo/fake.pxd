from .. cimport pkgcraft_c as C
from . cimport Repo


cdef class FakeRepo(Repo):
    pass
