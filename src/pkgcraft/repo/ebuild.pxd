from .. cimport pkgcraft_c as C
from ..pkg cimport EbuildPkg
from . cimport Repo

cdef class EbuildRepo(Repo):
    # cached fields
    cdef tuple _masters

    @staticmethod
    cdef EbuildRepo from_ptr(const C.Repo *, bint)

    cdef EbuildPkg create_pkg(self, C.Pkg *)
