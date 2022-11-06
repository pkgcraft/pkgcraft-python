from .. cimport pkgcraft_c as C
from ..pkg cimport EbuildPkg
from . cimport Repo
from ..error import PkgcraftError


cdef class EbuildRepo(Repo):
    """Ebuild package repo."""

    def __init__(self, path, id=None, priority=0):
        """Create an ebuild repo from a given path.

        This is for internal use only and requires adding the resulting
        EbuildRepo object to a Config object via add_repo() otherwise a panic
        will occur on usage.
        """
        path = str(path)
        id = str(id) if id is not None else path

        repo = C.pkgcraft_repo_ebuild_from_path(id.encode(), int(priority), path.encode())
        if repo is NULL:
            raise PkgcraftError

        self._repo = repo
        self._ref = False

    @staticmethod
    cdef EbuildRepo from_ptr(const C.Repo *repo, bint ref):
        """Create an instance from a repo pointer."""
        obj = <EbuildRepo>EbuildRepo.__new__(EbuildRepo)
        obj._repo = <C.Repo *>repo
        obj._ref = ref
        return obj

    cdef EbuildPkg create_pkg(self, C.Pkg *pkg):
        return EbuildPkg.from_ptr(pkg)

    @property
    def masters(self):
        """Get an ebuild repo's masters."""
        cdef size_t length
        if self._masters is None:
            repos = C.pkgcraft_ebuild_repo_masters(self._repo, &length)
            self._masters = tuple(EbuildRepo.from_ptr(repos[i], False) for i in range(length))
        return self._masters
