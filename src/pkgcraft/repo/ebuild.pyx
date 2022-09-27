from .. cimport pkgcraft_c as C
from ..config cimport Config
from ..pkg cimport EbuildPkg
from . cimport Repo
from ..error import PkgcraftError


cdef class EbuildRepo(Repo):
    """Ebuild package repo."""

    def __init__(self, conf, path, id=None, priority=0):
        config = <Config?>conf;
        path = str(path)
        id = str(id) if id is not None else path

        repo = C.pkgcraft_config_add_repo_path(
            config._config, id.encode(), int(priority), path.encode())
        if repo is NULL:
            raise PkgcraftError

        # force config repos attr refresh to get correct dict ordering by repo priority
        config._repos = None

        format = C.pkgcraft_repo_format(repo)
        if format is not C.RepoFormat.EbuildRepo:
            raise PkgcraftError('non-ebuild repo format')

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
