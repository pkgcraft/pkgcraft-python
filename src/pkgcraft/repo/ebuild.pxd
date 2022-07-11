from .. cimport pkgcraft_c as C
from ..pkg cimport EbuildPkg
from . cimport Repo

cdef class EbuildRepo(Repo):
    cdef const C.EbuildRepo *_ebuild_repo
    # cached fields
    cdef tuple _masters

    @staticmethod
    cdef EbuildRepo from_ptr(const C.Repo *)
    @staticmethod
    cdef EbuildRepo from_ref(const C.Repo *)

    cdef EbuildPkg create_pkg(self, C.Pkg *)
