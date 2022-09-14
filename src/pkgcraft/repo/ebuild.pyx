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

        if repo_conf.format is not C.RepoFormat.Ebuild:
            raise PkgcraftError('non-ebuild repo format')

        self._repo = <C.Repo *>repo_conf.repo
        self._ebuild_repo = C.pkgcraft_repo_as_ebuild(self._repo)
        self._ref = False
        C.pkgcraft_repo_config_free(repo_conf)

    @staticmethod
    cdef EbuildRepo from_ptr(const C.Repo *repo, bint ref):
        """Create an instance from a repo pointer."""
        obj = <EbuildRepo>EbuildRepo.__new__(EbuildRepo)
        obj._repo = <C.Repo *>repo
        obj._ebuild_repo = C.pkgcraft_repo_as_ebuild(obj._repo)
        if obj._ebuild_repo is NULL:  # pragma: no cover
            raise PkgcraftError
        obj._ref = ref
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
    def masters(self):
        """Get an ebuild repo's masters."""
        cdef C.Repo **repos
        cdef size_t length

        if self._masters is None:
            repos = C.pkgcraft_ebuild_repo_masters(self._ebuild_repo, &length)
            self._masters = tuple(EbuildRepo.from_ptr(repos[i], False) for i in range(length))
        return self._masters
