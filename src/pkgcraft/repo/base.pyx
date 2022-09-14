from .. cimport pkgcraft_c as C
from ..pkg cimport Pkg
from ..restrict cimport Restrict
from .. import parse
from ..restrict import InvalidRestrict


cdef class Repo:
    """Package repo."""

    def __init__(self):
        raise RuntimeError(f"{self.__class__.__name__} class doesn't support manual construction")

    cdef Pkg create_pkg(self, C.Pkg *pkg):  # pragma: no cover
        raise RuntimeError(f"{self.__class__.__name__} class doesn't support package creation")

    @property
    def id(self):
        """Get a repo's id."""
        cdef char *c_str
        if self._id is None:
            c_str = C.pkgcraft_repo_id(self._repo)
            self._id = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._id

    @property
    def path(self):
        """Get a repo's path."""
        cdef char *c_str
        if self._path is None:
            c_str = C.pkgcraft_repo_path(self._repo)
            self._path = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._path

    @property
    def categories(self):
        """Get a repo's categories."""
        cdef char **cats
        cdef size_t length

        cats = C.pkgcraft_repo_categories(self._repo, &length)
        categories = tuple(cats[i].decode() for i in range(length))
        C.pkgcraft_str_array_free(cats, length)
        return categories

    def packages(self, str cat not None):
        """Get a repo's packages for a category."""
        cdef char **pkgs
        cdef size_t length

        if parse.category(cat):
            pkgs = C.pkgcraft_repo_packages(self._repo, cat.encode(), &length)
            packages = tuple(pkgs[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(pkgs, length)
            return packages

    def versions(self, str cat not None, str pkg not None):
        """Get a repo's versions for a package."""
        cdef char **vers
        cdef size_t length

        if parse.category(cat) and parse.package(pkg):
            vers = C.pkgcraft_repo_versions(self._repo, cat.encode(), pkg.encode(), &length)
            versions = tuple(vers[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(vers, length)
            return versions

    def __len__(self):
        return C.pkgcraft_repo_len(self._repo)

    def __contains__(self, obj not None):
        if isinstance(obj, str):
            return C.pkgcraft_repo_contains_path(self._repo, obj.encode())
        return bool(next(self.iter_restrict(obj), None))

    def __getitem__(self, obj not None):
        try:
            return next(self.iter_restrict(obj))
        except (StopIteration, InvalidRestrict):
            raise KeyError(obj)

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
        if not self._hash:
            self._hash = C.pkgcraft_repo_hash(self._repo)
        return self._hash

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
        cdef Restrict r = obj if isinstance(obj, Restrict) else Restrict(obj)
        o = <_RestrictIter>_RestrictIter.__new__(_RestrictIter)
        o._repo = repo
        o._iter = C.pkgcraft_repo_restrict_iter(repo._repo, r._restrict)
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
