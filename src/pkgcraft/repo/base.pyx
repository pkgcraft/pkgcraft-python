import os
from pathlib import Path

from .. cimport pkgcraft_c as C
from ..atom cimport Cpv
from ..pkg cimport Pkg
from ..restrict cimport Restrict
from . cimport EbuildRepo, FakeRepo
from .. import parse
from ..error import IndirectInit, PkgcraftError


cdef class Repo:
    """Package repo."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    cdef inject_ptr(self, const C.Repo *repo, bint ref):
        """Overwrite the repo pointer with a given value."""
        self.ptr = <C.Repo *>repo
        self.ref = ref

    @staticmethod
    cdef Repo from_ptr(C.Repo *ptr, bint ref):
        """Convert a repo pointer to a repo object."""
        format = C.pkgcraft_repo_format(ptr)
        if format is C.RepoFormat.REPO_FORMAT_EBUILD:
            return EbuildRepo.from_ptr(ptr, ref)
        elif format is C.RepoFormat.REPO_FORMAT_FAKE:
            return FakeRepo.from_ptr(ptr, ref)
        else:  # pragma: no cover
            raise PkgcraftError('unsupported repo format')

    cdef Pkg create_pkg(self, C.Pkg *ptr):  # pragma: no cover
        raise RuntimeError(f"{self.__class__.__name__} class doesn't support package creation")

    @property
    def id(self):
        """Get a repo's id."""
        if self._id is None:
            c_str = C.pkgcraft_repo_id(self.ptr)
            self._id = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._id

    @property
    def path(self):
        """Get a repo's path."""
        if self._path is None:
            c_str = C.pkgcraft_repo_path(self.ptr)
            self._path = Path(c_str.decode())
            C.pkgcraft_str_free(c_str)
        return self._path

    @property
    def categories(self):
        """Get a repo's categories."""
        cdef size_t length
        cats = C.pkgcraft_repo_categories(self.ptr, &length)
        categories = tuple(cats[i].decode() for i in range(length))
        C.pkgcraft_str_array_free(cats, length)
        return categories

    def packages(self, str cat not None):
        """Get a repo's packages for a category."""
        cdef size_t length
        if parse.category(cat):
            pkgs = C.pkgcraft_repo_packages(self.ptr, cat.encode(), &length)
            packages = tuple(pkgs[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(pkgs, length)
            return packages

    def versions(self, str cat not None, str pkg not None):
        """Get a repo's versions for a package."""
        cdef size_t length
        if parse.category(cat) and parse.package(pkg):
            vers = C.pkgcraft_repo_versions(self.ptr, cat.encode(), pkg.encode(), &length)
            versions = tuple(vers[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(vers, length)
            return versions

    def __len__(self):
        return C.pkgcraft_repo_len(self.ptr)

    def __bool__(self):
        return not C.pkgcraft_repo_is_empty(self.ptr)

    def __contains__(self, obj):
        if isinstance(obj, os.PathLike):
            return C.pkgcraft_repo_contains_path(self.ptr, str(obj).encode())
        return bool(next(self.iter_restrict(obj), None))

    def __getitem__(self, obj):
        try:
            cpv = Cpv(obj) if isinstance(obj, str) else <Cpv?>obj
            return next(self.iter_restrict(cpv))
        except StopIteration:
            raise KeyError(obj)

    def __iter__(self):
        if self.iter_ptr is not NULL:
            C.pkgcraft_repo_iter_free(self.iter_ptr)
        self.iter_ptr = C.pkgcraft_repo_iter(self.ptr)
        return self

    def __next__(self):
        # verify __iter__() was called since cython's generated next() method doesn't check
        if self.iter_ptr is NULL:
            raise TypeError(f"{self.__class__.__name__!r} object is not an iterator")

        pkg = C.pkgcraft_repo_iter_next(self.iter_ptr)
        if pkg is not NULL:
            return self.create_pkg(pkg)
        raise StopIteration

    def iter_restrict(self, restrict not None):
        """Iterate over a repo's packages while applying a restriction."""
        yield from _RestrictIter.create(self, restrict)

    def __lt__(self, Repo other):
        return C.pkgcraft_repo_cmp(self.ptr, other.ptr) == -1

    def __le__(self, Repo other):
        return C.pkgcraft_repo_cmp(self.ptr, other.ptr) <= 0

    def __eq__(self, Repo other):
        return C.pkgcraft_repo_cmp(self.ptr, other.ptr) == 0

    def __ne__(self, Repo other):
        return C.pkgcraft_repo_cmp(self.ptr, other.ptr) != 0

    def __gt__(self, Repo other):
        return C.pkgcraft_repo_cmp(self.ptr, other.ptr) == 1

    def __ge__(self, Repo other):
        return C.pkgcraft_repo_cmp(self.ptr, other.ptr) >= 0

    def __str__(self):
        return self.id

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        if not self._hash:
            self._hash = C.pkgcraft_repo_hash(self.ptr)
        return self._hash

    def __dealloc__(self):
        if not self.ref:
            C.pkgcraft_repo_free(self.ptr)
        C.pkgcraft_repo_iter_free(self.iter_ptr)


cdef class _RestrictIter:
    """Iterator that applies a restriction over a repo iterator."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    @staticmethod
    cdef _RestrictIter create(Repo repo, object obj):
        cdef Restrict r = obj if isinstance(obj, Restrict) else Restrict(obj)
        o = <_RestrictIter>_RestrictIter.__new__(_RestrictIter)
        o.repo = repo
        o.ptr = C.pkgcraft_repo_restrict_iter(repo.ptr, r.ptr)
        return o

    def __iter__(self):
        return self

    def __next__(self):
        # verify __iter__() was called since cython's generated next() method doesn't check
        if self.ptr is NULL:  # pragma: no cover
            raise TypeError(f"{self.__class__.__name__!r} object is not an iterator")

        pkg = C.pkgcraft_repo_restrict_iter_next(self.ptr)
        if pkg is not NULL:
            return self.repo.create_pkg(pkg)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_repo_restrict_iter_free(self.ptr)
