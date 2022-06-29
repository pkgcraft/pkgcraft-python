from .. cimport pkgcraft_c as C
from ..pkg cimport EbuildPkg
from ..error import PkgcraftError
from .base import Repo


cdef class EbuildRepo(Repo):
    """Ebuild package repo."""

    @staticmethod
    cdef EbuildRepo from_ptr(const C.Repo *repo):
        """Create instance from an owned pointer."""
        # skip calling __init__()
        obj = <EbuildRepo>EbuildRepo.__new__(EbuildRepo)
        obj._repo = <C.Repo *>repo
        obj._ebuild_repo = C.pkgcraft_repo_as_ebuild(obj._repo)
        if obj._ebuild_repo is NULL:
            raise PkgcraftError
        return obj

    @staticmethod
    cdef EbuildRepo from_ref(const C.Repo *repo):
        """Create instance from a borrowed pointer."""
        cdef EbuildRepo obj = EbuildRepo.from_ptr(repo)
        obj._ref = True
        return obj

    cdef EbuildPkg create_pkg(self, C.Pkg *pkg):
        # create instance without calling __init__()
        obj = <EbuildPkg>EbuildPkg.__new__(EbuildPkg)
        obj._pkg = <C.Pkg *>pkg
        obj._ebuild_pkg = <C.EbuildPkg *>C.pkgcraft_pkg_as_ebuild(pkg)
        if obj._ebuild_pkg is NULL:
            raise PkgcraftError
        return obj

    @property
    def category_dirs(self):
        """Get an ebuild repo's category dirs."""
        cdef char **array
        cdef size_t length

        array = C.pkgcraft_ebuild_repo_category_dirs(<C.EbuildRepo *>self._ebuild_repo, &length)
        dirs = tuple(array[i].decode() for i in range(length))
        C.pkgcraft_str_array_free(array, length)
        return dirs
