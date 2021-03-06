from .. cimport pkgcraft_c as C
from ..pkg cimport Pkg
from ..atom cimport Cpv
from ..error import PkgcraftError


cdef class Repo:
    """Package repo."""

    def __init__(self):
        raise RuntimeError(f"{self.__class__.__name__} class doesn't support manual construction")

    cdef Pkg create_pkg(self, C.Pkg *pkg):  # pragma: no cover
        raise RuntimeError(f"{self.__class__.__name__} class doesn't support package creation")

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

    def iter_restrict(self, restrict not None):
        """Iterate over a repo's packages while applying a restriction."""
        yield from _RestrictIter.create(self, restrict)

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


cdef class _RestrictIter:
    """Iterator that applies a restriction over a repo iterator."""

    def __init__(self):  # pragma: no cover
        raise RuntimeError(f"{self.__class__.__name__} class doesn't support manual construction")

    @staticmethod
    cdef _RestrictIter create(Repo repo, object obj):
        cdef C.Restrict *restrict

        if isinstance(obj, Cpv):
            restrict = C.pkgcraft_atom_restrict((<Cpv>obj)._atom)
        elif isinstance(obj, Pkg):
            restrict = C.pkgcraft_pkg_restrict((<Pkg>obj)._pkg)
        elif isinstance(obj, str):
            restrict = C.pkgcraft_restrict_parse(obj.encode())
        else:
            raise TypeError(f"{obj.__class__.__name__!r} unsupported restriction type")

        if restrict is NULL:
            raise PkgcraftError

        # create instance without calling __init__()
        o = <_RestrictIter>_RestrictIter.__new__(_RestrictIter)
        o._repo = repo
        o._iter = C.pkgcraft_repo_restrict_iter(repo._repo, restrict)
        C.pkgcraft_restrict_free(restrict)
        return o

    def __iter__(self):
        return self

    def __next__(self):
        # verify __iter__() was called since cython's generated next() method doesn't check
        if self._iter is NULL:  # pragma: no cover
            raise TypeError(f"{self.__class__.__name__!r} object is not an iterator")

        cdef C.Pkg *pkg = C.pkgcraft_repo_restrict_iter_next(self._iter)
        if pkg is not NULL:
            return self._repo.create_pkg(pkg)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_repo_restrict_iter_free(self._iter)
