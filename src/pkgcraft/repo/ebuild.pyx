from .. cimport pkgcraft_c as C
from ..pkg cimport EbuildPkg
from . cimport Repo
from ..error import PkgcraftError


cdef class EbuildRepo(Repo):
    """Ebuild package repo."""

    @staticmethod
    cdef EbuildRepo from_ptr(const C.Repo *repo):
        """Create instance from an owned pointer."""
        # skip calling __init__()
        obj = <EbuildRepo>EbuildRepo.__new__(EbuildRepo)
        obj._repo = <C.Repo *>repo
        obj._ebuild_repo = C.pkgcraft_repo_as_ebuild(obj._repo)
        if obj._ebuild_repo is NULL:  # pragma: no cover
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
        if obj._ebuild_pkg is NULL:  # pragma: no cover
            raise PkgcraftError
        return obj

    @property
    def category_dirs(self):
        """Get an ebuild repo's category dirs."""
        cdef char **dirs
        cdef size_t length

        dirs = C.pkgcraft_ebuild_repo_category_dirs(self._ebuild_repo, &length)
        categories = tuple(dirs[i].decode() for i in range(length))
        C.pkgcraft_str_array_free(dirs, length)
        return categories

    @property
    def masters(self):
        """Get an ebuild repo's masters."""
        cdef C.Repo **repos
        cdef size_t length

        if self._masters is None:
            repos = C.pkgcraft_ebuild_repo_masters(self._ebuild_repo, &length)
            self._masters = tuple(EbuildRepo.from_ptr(repos[i]) for i in range(length))
        return self._masters
