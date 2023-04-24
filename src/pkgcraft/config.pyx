import os

cimport cython

from . cimport pkgcraft_c as C
from ._misc cimport ptr_to_str
from .repo cimport Repo, RepoSet
from .error import ConfigError, PkgcraftError

# default fallback paths when running Config.load_repos_conf() with no path argument.
# TODO: determine paths based off install prefix?
PORTAGE_REPOS_CONF_DEFAULTS = (
    '/etc/portage/repos.conf',
    '/usr/share/portage/config/repos.conf',
)


cdef dict repos_to_dict(C.Repo **c_repos, size_t length, bint ref):
    """Convert an array of repos to an (id, Repo) mapping."""
    d = {}
    for i in range(length):
        ptr = c_repos[i]
        id = ptr_to_str(C.pkgcraft_repo_id(ptr))
        d[id] = Repo.from_ptr(ptr, ref)
    return d


cdef class Config:
    """Config for the system."""

    def __init__(self):
        self.ptr = C.pkgcraft_config_new()

    @property
    def repos(self):
        """Return the config's repo mapping."""
        if self._repos is None:
            self._repos = Repos.from_config(self.ptr)
        return self._repos

    cdef Repo add_repo_path(self, object path, object id, int priority):
        """Add an external repo via its file path and return its pointer."""
        path = str(path)
        id = str(id) if id is not None else path

        cdef C.Repo *ptr = C.pkgcraft_config_add_repo_path(
            self.ptr, id.encode(), int(priority), path.encode())
        if ptr is NULL:
            raise PkgcraftError

        # force repos attr refresh
        self._repos = None

        return Repo.from_ptr(ptr, False)

    def add_repo(self, repo not None, id=None, priority=0):
        """Add an external repo via its file path or from a Repo object."""
        if isinstance(repo, (str, os.PathLike)):
            path = str(repo)
            return self.add_repo_path(path, id, priority)
        else:
            if C.pkgcraft_config_add_repo(self.ptr, (<Repo?>repo).ptr) is NULL:
                raise ConfigError
            self._repos = None
            return repo

    def load_repos_conf(self, path=None, defaults=PORTAGE_REPOS_CONF_DEFAULTS):
        """Load repos from a given path to a portage-compatible repos.conf directory or file."""
        cdef C.Repo **c_repos
        cdef size_t length

        if path is None:
            for path in defaults:
                if os.path.exists(path):
                    break
            else:
                raise ValueError('no repos.conf found on the system')

        c_repos = C.pkgcraft_config_load_repos_conf(self.ptr, str(path).encode(), &length)
        if c_repos is NULL:
            raise PkgcraftError

        # force repos attr refresh
        self._repos = None

        d = repos_to_dict(c_repos, length, False)
        C.pkgcraft_array_free(<void **>c_repos, length)
        return d

    def __dealloc__(self):
        C.pkgcraft_config_free(self.ptr)


@cython.final
cdef class Repos:

    @staticmethod
    cdef Repos from_config(C.Config *ptr):
        cdef size_t length
        c_repos = <C.Repo **>C.pkgcraft_config_repos(ptr, &length)
        obj = <Repos>Repos.__new__(Repos)
        obj.config_ptr = ptr
        obj._repos = repos_to_dict(c_repos, length, True)
        C.pkgcraft_array_free(<void **>c_repos, length)
        return obj

    @property
    def all(self):
        """Return the set of all repos."""
        if self._all is None:
            ptr = C.pkgcraft_config_repos_set(self.config_ptr, C.REPO_SET_TYPE_ALL)
            self._all = RepoSet.from_ptr(ptr)
        return self._all

    @property
    def ebuild(self):
        """Return the set of all ebuild repos."""
        if self._ebuild is None:
            ptr = C.pkgcraft_config_repos_set(self.config_ptr, C.REPO_SET_TYPE_EBUILD)
            self._ebuild = RepoSet.from_ptr(ptr)
        return self._ebuild

    def __eq__(self, other):
        return self._repos == other

    def __contains__(self, obj):
        return obj in self._repos

    def __getitem__(self, key):
        return self._repos[key]

    def get(self, key, default=None):
        return self._repos.get(key, default)

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
