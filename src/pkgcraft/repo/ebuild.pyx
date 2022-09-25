from .. cimport pkgcraft_c as C
from ..config cimport Config
from ..pkg cimport EbuildPkg
from . cimport Repo
from ..error import PkgcraftError


cdef class EbuildRepo(Repo):
    """Ebuild package repo."""

    def __init__(self, Config config not None, object path not None, str id=None, int priority=0):
        cdef C.RepoConfig *repo_conf
        path = str(path)
        id = id if id is not None else path

        repo_conf = C.pkgcraft_config_add_repo_path(
            config._config, id.encode(), priority, path.encode())
        if repo_conf is NULL:
            raise PkgcraftError

        # force config repos attr refresh to get correct dict ordering by repo priority
        config._repos = None

        if repo_conf.format is not C.RepoFormat.EbuildRepo:
            raise PkgcraftError('non-ebuild repo format')

        self._repo = <C.Repo *>repo_conf.repo
        self._ref = False
        C.pkgcraft_repo_config_free(repo_conf)

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
        cdef C.Repo **repos
        cdef size_t length

        if self._masters is None:
            repos = C.pkgcraft_ebuild_repo_masters(self._repo, &length)
            self._masters = tuple(EbuildRepo.from_ptr(repos[i], False) for i in range(length))
        return self._masters
