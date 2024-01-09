import os

cimport cython

from . cimport C
from ._misc cimport cstring_to_str
from .error cimport Indirect
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


@cython.final
cdef class Config:
    """Config for the system.

    On instance creation, no system config is automatically loaded.
    """
    def __cinit__(self):
        self.ptr = C.pkgcraft_config_new()

    @property
    def repos(self):
        """Return the config's repo mapping.

        Returns:
            Repos:
        """
        if self._repos is None:
            self._repos = Repos.from_config(self.ptr)
        return self._repos

    cdef Repo add_repo_path(self, object path, object id, int priority, bint external=True):
        """Add a repo via its file path and return the Repo object."""
        path = str(path)
        id = str(id) if id is not None else path

        ptr = C.pkgcraft_config_add_repo_path(
            self.ptr, id.encode(), int(priority), path.encode(), external)
        if ptr is NULL:
            raise PkgcraftError

        # force repos attr refresh
        self._repos = None

        return Repo.from_ptr(ptr)

    def add_repo(self, repo not None, id=None, priority=0, external=True):
        """Add a repo via its file path or from a Repo object and return the Repo object.

        Args:
            repo (str | Repo): path to a repo or a repo object
            id (str | None): repo identifier, if None the path is used
            priority (int): repo priority
            external (bool): repo is external from the system config

        Returns:
            Repo: the repo object (subclassed to its format) added to the config

        Raises:
            PkgcraftError: on invalid repos
            ConfigError: on overlap between repos in the config object
        """
        if isinstance(repo, (str, os.PathLike)):
            path = str(repo)
            return self.add_repo_path(path, id, priority, external)
        else:
            if C.pkgcraft_config_add_repo(self.ptr, (<Repo?>repo).ptr, external) is NULL:
                raise ConfigError
            self._repos = None
            return repo

    def load(self):
        """Load pkgcraft config files, if none are found revert to loading portage files.

        Raises:
            PkgcraftError: on config loading failures
        """
        if C.pkgcraft_config_load(self.ptr) is NULL:
            raise PkgcraftError

        # force repos attr refresh
        self._repos = None

    def load_portage_conf(self, path=None):
        """Load portage config files from a given directory, falling back to default locations.

        Args:
            path (str): path to the portage config directory to load, by
                default the standard locations are used

        Raises:
            PkgcraftError: on config loading failures
        """
        path = str(path).encode() if path is not None else None
        if C.pkgcraft_config_load_portage_conf(self.ptr, path) is NULL:
            raise PkgcraftError

        # force repos attr refresh
        self._repos = None

    def __dealloc__(self):
        C.pkgcraft_config_free(self.ptr)


@cython.final
cdef class Repos(Indirect):
    """Wrapper for all known repos."""

    cdef C.Config *ptr

    # cached fields
    cdef dict _repos
    cdef RepoSet _all
    cdef RepoSet _ebuild
    cdef RepoSet _configured

    @staticmethod
    cdef Repos from_config(C.Config *ptr):
        cdef size_t length
        c_repos = <C.Repo **>C.pkgcraft_config_repos(ptr, &length)
        inst = <Repos>Repos.__new__(Repos)
        inst.ptr = ptr
        inst._repos = repos_to_dict(c_repos, length, True)
        C.pkgcraft_array_free(<void **>c_repos, length)
        return inst

    @property
    def all(self):
        """Return the set of all repos.

        Returns:
            RepoSet:
        """
        if self._all is None:
            ptr = C.pkgcraft_config_repos_set(self.ptr, NULL)
            self._all = RepoSet.from_ptr(ptr)
        return self._all

    @property
    def ebuild(self):
        """Return the set of all ebuild repos.

        Returns:
            RepoSet:
        """
        cdef C.RepoFormat fmt = C.REPO_FORMAT_EBUILD
        if self._ebuild is None:
            ptr = C.pkgcraft_config_repos_set(self.ptr, &fmt)
            self._ebuild = RepoSet.from_ptr(ptr)
        return self._ebuild

    @property
    def configured(self):
        """Return the set of all configured repos.

        Returns:
            RepoSet:
        """
        cdef C.RepoFormat fmt = C.REPO_FORMAT_CONFIGURED
        if self._configured is None:
            ptr = C.pkgcraft_config_repos_set(self.ptr, &fmt)
            self._configured = RepoSet.from_ptr(ptr)
        return self._configured

    def get(self, key, default=None):
        """Get the repo associated with a given key.

        Args:
            default: fallback value when no matching key exists

        Returns:
            Repo | None: the repo object if it exists, otherwise the fallback value
        """
        return self._repos.get(key, default)

    def __eq__(self, other):
        return self._repos == other

    def __contains__(self, obj):
        return obj in self._repos

    def __getitem__(self, key):
        if isinstance(key, int):
            return list(self._repos.values())[key]
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
