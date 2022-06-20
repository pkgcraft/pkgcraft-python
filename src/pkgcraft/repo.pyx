# SPDX-License-Identifier: MIT
# cython: language_level=3

from . cimport pkgcraft_c as C
from .error import PkgcraftError


cdef class Repo:
    """Package repo."""

    @staticmethod
    cdef Repo borrowed(const C.Repo *repo):
        # create instance without calling __init__()
        obj = <Repo>Repo.__new__(Repo)
        obj._repo = <C.Repo *>repo
        return obj

    @property
    def id(self):
        """Get a repo's id."""
        cdef char* c_str = C.pkgcraft_repo_id(self._repo)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __lt__(self, Repo other):
        return C.pkgcraft_repo_cmp(self._repo, other._repo) == -1

    def __le__(self, Repo other):
        return C.pkgcraft_repo_cmp(self._repo, other._repo) <= 0

    def __eq__(self, Repo other):
        return C.pkgcraft_repo_cmp(self._repo, other._repo) == 0

    def __ne__(self, Repo other):
        return C.pkgcraft_repo_cmp(self._repo, other._repo) != 0

    def __gt__(self, Repo other):
        return C.pkgcraft_repo_cmp(self._repo, other._repo) == 1

    def __ge__(self, Repo other):
        return C.pkgcraft_repo_cmp(self._repo, other._repo) >= 0

    def __str__(self):
        return self.id

    def __repr__(self):
        cdef size_t addr = <size_t>&self._repo
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        return C.pkgcraft_repo_hash(self._repo)
