from . cimport pkgcraft_c as C
from .repo cimport EbuildRepo
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
        if self._repos is None:
            self._repos = Repos.from_config(self._config)
        return self._repos

    def add_repo_path(self, path not None, str id=None, int priority=0):
        """Add an external repo via its file path."""
        cdef C.Repo *repo
        cdef C.RepoFormat format
        path = str(path)
        id = id if id is not None else path

        repo = C.pkgcraft_config_add_repo_path(
            self._config, id.encode(), priority, path.encode())
        if repo is NULL:
            raise PkgcraftError

        # force repos attr refresh to get correct dict ordering by repo priority
        self._repos = None

        format = C.pkgcraft_repo_format(repo)
        if format is C.RepoFormat.EbuildRepo:
            r = EbuildRepo.from_ptr(repo, False)
        else:
            raise PkgcraftError('unsupported repo format')

        return r

    # TODO: determine default fs path based off install prefix?
    def load_repos_conf(self, path='/etc/portage/repos.conf'):
        """Load repos from a given path to a portage-compatible repos.conf directory or file."""
        cdef C.Repo **repos
        cdef C.RepoFormat format
        cdef char *id
        cdef size_t length
        cdef dict d
        path = str(path)

        repos = C.pkgcraft_config_load_repos_conf(self._config, path.encode(), &length)
        if repos is NULL:
            raise PkgcraftError

        # force repos attr refresh to get correct dict ordering by repo priority
        self._repos = None

        d = {}
        for i in range(length):
            r = repos[i]
            format = C.pkgcraft_repo_format(r)
            if format is C.RepoFormat.EbuildRepo:
                repo = EbuildRepo.from_ptr(r, False)
            else:
                raise PkgcraftError('unsupported repo format')
            id = C.pkgcraft_repo_id(r)
            d[id.decode()] = repo
            C.pkgcraft_str_free(id)
        C.pkgcraft_repos_free(repos, length)

        return d

    def __dealloc__(self):
        C.pkgcraft_config_free(self._config)


cdef class Repos:
    """Available repos for the system."""

    @staticmethod
    cdef Repos from_config(C.Config *config):
        cdef size_t length
        cdef C.Repo **repos = C.pkgcraft_config_repos(config, &length)
        cdef C.RepoFormat format
        cdef char *id
        obj = <Repos>Repos.__new__(Repos)
        obj._repos = {}

        for i in range(length):
            r = repos[i]
            format = C.pkgcraft_repo_format(r)
            if format is C.RepoFormat.EbuildRepo:
                repo = EbuildRepo.from_ptr(r, False)
            else:
                raise PkgcraftError('unsupported repo format')
            id = C.pkgcraft_repo_id(r)
            obj._repos[id.decode()] = repo
            C.pkgcraft_str_free(id)

        C.pkgcraft_repos_free(repos, length)
        return obj

    def __getitem__(self, key):
        return self._repos[key]

    def __str__(self):
        return str(self._repos)

    def __repr__(self):
        return repr(self._repos)

    def __bool__(self):
        return bool(self._repos)

    def __iter__(self):
        return iter(self._repos)

    def __len__(self):
        return len(self._repos)
