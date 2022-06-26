from .. cimport pkgcraft_c as C
from ..pkg cimport Pkg
from ..error import PkgcraftError


cdef class Repo:
    """Package repo."""

    def __init__(self):
        raise PkgcraftError(f"{self.__class__} doesn't support regular creation")

    @staticmethod
    cdef Repo from_ptr(const C.Repo *repo):
        """Create instance from an owned pointer."""
        # skip calling __init__()
        obj = <Repo>Repo.__new__(Repo)
        obj._repo = <C.Repo *>repo
        return obj

    @staticmethod
    cdef Repo from_ref(const C.Repo *repo):
        """Create instance from a borrowed pointer."""
        cdef Repo obj = Repo.from_ptr(repo)
        obj._ref = True
        return obj

    cdef Pkg create_pkg(self, C.Pkg *pkg):
        # create instance without calling __init__()
        obj = <Pkg>Pkg.__new__(Pkg)
        obj._pkg = <C.Pkg *>pkg
        return obj

    @property
    def id(self):
        """Get a repo's id."""
        cdef char *c_str = C.pkgcraft_repo_id(self._repo)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __len__(self):
        return C.pkgcraft_repo_len(self._repo)

    def __iter__(self):
        if self._repo_iter is not NULL:
            C.pkgcraft_repo_iter_free(self._repo_iter)
        self._repo_iter = C.pkgcraft_repo_iter(self._repo)
        return self

    def __next__(self):
        # verify __iter__() was called since cython's generated next() method doesn't check
        if self._repo_iter is NULL:
            raise TypeError(f"{self.__class__.__name__!r} object is not an iterator")

        cdef C.Pkg *pkg = C.pkgcraft_repo_iter_next(self._repo_iter)
        if pkg is not NULL:
            return self.create_pkg(pkg)
        raise StopIteration

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

    def __dealloc__(self):
        if not self._ref:
            C.pkgcraft_repo_free(self._repo)
        C.pkgcraft_repo_iter_free(self._repo_iter)
