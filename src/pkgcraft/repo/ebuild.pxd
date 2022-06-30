from .. cimport pkgcraft_c as C
from ..pkg cimport EbuildPkg
from .base cimport Repo

cdef class EbuildRepo(Repo):
    cdef C.EbuildRepo *_ebuild_repo

    @staticmethod
    cdef EbuildRepo from_ptr(const C.Repo *)
    @staticmethod
    cdef EbuildRepo from_ref(const C.Repo *)

    cdef EbuildPkg create_pkg(self, C.Pkg *)
