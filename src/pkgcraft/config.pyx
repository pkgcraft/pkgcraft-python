from . cimport pkgcraft_c as C
from .repo cimport EbuildRepo, Repo
from ._misc import ImmutableDict
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
                    repo = Repo.from_ref(r.repo)
                d[r.id.decode()] = repo
            C.pkgcraft_repos_free(repos, length)
            self._repos = ImmutableDict(d)
        return self._repos

    def add_repo_path(self, str path not None, str id=None, int priority=0):
        cdef C.RepoConfig *repo_conf
        path_bytes = path.encode()
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
            r = Repo.from_ptr(repo_conf.repo)

        C.pkgcraft_repo_config_free(repo_conf)
        return r

    def __dealloc__(self):
        C.pkgcraft_config_free(self._config)
