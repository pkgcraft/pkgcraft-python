from types import MappingProxyType

from . cimport pkgcraft_c as C
from .repo cimport EbuildRepo, Repo
from .error import PkgcraftError


cdef class Config:
    """Config for the system."""

    def __init__(self):
        self._config = C.pkgcraft_config()
        if self._config is NULL:
            raise PkgcraftError

    @property
    def repos(self):
        """Return the config's repo mapping."""
        cdef C.RepoConfig **repos
        cdef size_t length
        cdef dict d

        if self._repos is None:
            repos = C.pkgcraft_config_repos(self._config, &length)
            d = {}
            for i in range(length):
                r = repos[i]
                if r.format is C.RepoFormat.Ebuild:
                    repo = EbuildRepo.from_ref(r.repo)
                else:
                    raise PkgcraftError('unsupported repo format')
                d[r.id.decode()] = repo
            C.pkgcraft_repos_free(repos, length)
            self._repos = MappingProxyType(d)
        return self._repos

    def add_repo_path(self, path not None, str id=None, int priority=0):
        """Add an external repo via its file path."""
        cdef C.RepoConfig *repo_conf
        path_bytes = str(path).encode()
        id_bytes = id.encode() if id is not None else path_bytes
        cdef char *path_p = path_bytes
        cdef char *id_p = id_bytes

        repo_conf = C.pkgcraft_config_add_repo_path(self._config, id_p, priority, path_p)
        if repo_conf is NULL:
            raise PkgcraftError

        # reset cached repos
        self._repos = None

        if repo_conf.format is C.RepoFormat.Ebuild:
            r = EbuildRepo.from_ptr(repo_conf.repo)
        else:
            raise PkgcraftError('unsupported repo format')

        C.pkgcraft_repo_config_free(repo_conf)
        return r

    def load_repos_conf(self, path not None):
        """Load repos from a given path to a portage-compatible repos.conf directory or file."""
        path_bytes = str(path).encode()
        cdef char *path_p = path_bytes

        if C.pkgcraft_config_load_repos_conf(self._config, path_p):
            raise PkgcraftError

        # reset cached repos
        self._repos = None

    def __dealloc__(self):
        C.pkgcraft_config_free(self._config)
