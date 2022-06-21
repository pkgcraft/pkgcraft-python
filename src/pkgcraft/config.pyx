# SPDX-License-Identifier: MIT
# cython: language_level=3

from . cimport pkgcraft_c as C
from .repo cimport Repo
from .error import PkgcraftError


cdef class Config:
    """Config for the system."""

    def __init__(self):
        self.load()

    @staticmethod
    def load():
        """Load the system config."""
        obj = <Config>Config.__new__(Config)
        obj._config = C.pkgcraft_config()
        if not obj._config:
            raise PkgcraftError
        return obj

    @property
    def repos(self):
        """Return the config's repo mapping."""
        cdef C.RepoConfig **repos
        cdef size_t length
        cdef dict d = {}

        if self._repos is None:
            repos = C.pkgcraft_config_repos(self._config, &length)
            if repos:
                for i in range(length):
                    r = repos[i]
                    d[r.id.decode()] = Repo.borrowed(r.repo)
                C.pkgcraft_repos_free(repos, length)
            self._repos = d
        return self._repos

    def add_repo(self, str path_str, str id_str=None, int priority=0):
        path_bytes = path_str.encode()
        id_bytes = id_str.encode() if id_str is not None else path_bytes
        cdef char* path = path_bytes
        cdef char* id = id_bytes

        cdef const C.Repo* repo = C.pkgcraft_config_add_repo(self._config, id, priority, path)
        if not repo:
            raise PkgcraftError

        # reset cached repos
        self._repos = None
        return Repo.borrowed(repo)

    def __dealloc__(self):
        C.pkgcraft_config_free(self._config)
