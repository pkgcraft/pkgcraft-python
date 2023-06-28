import os

cimport cython

from . cimport C
from ._misc cimport cstring_to_str
from .repo cimport Repo, RepoSet
from .error import ConfigError, PkgcraftError


cdef dict repos_to_dict(C.Repo **c_repos, size_t length, bint ref):
    """Convert an array of repos to an (id, Repo) mapping."""
    d = {}
    for i in range(length):
        ptr = c_repos[i]
        id = cstring_to_str(C.pkgcraft_repo_id(ptr))
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

    cdef Repo add_repo_path(self, object path, object id, int priority, bint external=True):
        """Add a repo via its file path and return the Repo object."""
        path = str(path)
        id = str(id) if id is not None else path

        cdef C.Repo *ptr = C.pkgcraft_config_add_repo_path(
            self.ptr, id.encode(), int(priority), path.encode(), external)
        if ptr is NULL:
            raise PkgcraftError

        # force repos attr refresh
        self._repos = None

        return Repo.from_ptr(ptr, False)

    def add_repo(self, repo not None, id=None, priority=0, external=True):
        """Add a repo via its file path or from a Repo object and return the Repo object."""
        if isinstance(repo, (str, os.PathLike)):
            path = str(repo)
            return self.add_repo_path(path, id, priority, external)
        else:
            if C.pkgcraft_config_add_repo(self.ptr, (<Repo?>repo).ptr, external) is NULL:
                raise ConfigError
            self._repos = None
            return repo

    def load(self):
        """Load pkgcraft config files, if none are found revert to loading portage files."""
        cdef C.Config *ptr = C.pkgcraft_config_load(self.ptr)
        if ptr is NULL:
            raise PkgcraftError

        # force repos attr refresh
        self._repos = None

    def load_portage_conf(self, path=None):
        """Load portage config files from a given directory, falling back to default locations."""
        path = str(path).encode() if path is not None else None
        cdef C.Config *ptr = C.pkgcraft_config_load_portage_conf(self.ptr, path)
        if ptr is NULL:
            raise PkgcraftError

        # force repos attr refresh
        self._repos = None

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
            ptr = C.pkgcraft_config_repos_set(self.config_ptr, C.REPOS_ALL)
            self._all = RepoSet.from_ptr(ptr)
        return self._all

    @property
    def ebuild(self):
        """Return the set of all ebuild repos."""
        if self._ebuild is None:
            ptr = C.pkgcraft_config_repos_set(self.config_ptr, C.REPOS_EBUILD)
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
