from .. cimport pkgcraft_c as C
from ..pkg cimport FakePkg
from . cimport Repo

cdef class FakeRepo(Repo):
    @staticmethod
    cdef FakeRepo from_ptr(const C.Repo *, bint)

    cdef FakePkg create_pkg(self, C.Pkg *)
