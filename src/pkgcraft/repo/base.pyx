import os
from pathlib import Path

from .. cimport pkgcraft_c as C
from ..dep cimport Cpv
from ..pkg cimport Pkg
from ..restrict cimport Restrict
from . cimport EbuildRepo, FakeRepo

from .. import parse
from ..error import InvalidRepo


cdef class Repo:
    """Package repo."""

    format = None

    def __init__(self, path not None, id=None, int priority=0):
        """Create a Repo from a path."""
        path = str(path)
        id = str(id) if id is not None else path

        # When called using a subclass try to load that type, otherwise try types in order.
        if self.format is not None:
            ptr = C.pkgcraft_repo_from_format(
                id.encode(), priority, path.encode(), self.format, True)
        else:
            ptr = C.pkgcraft_repo_from_path(id.encode(), priority, path.encode(), True)

        if ptr is NULL:
            raise InvalidRepo

        Repo.from_ptr(ptr, False, self)

    @staticmethod
    cdef Repo from_ptr(C.Repo *ptr, bint ref, Repo obj=None):
        """Create a Repo from a pointer."""
        if obj is None:
            format = C.pkgcraft_repo_format(ptr)
            if format == C.RepoFormat.REPO_FORMAT_EBUILD:
                obj = <EbuildRepo>EbuildRepo.__new__(EbuildRepo)
            elif format == C.RepoFormat.REPO_FORMAT_FAKE:
                obj = <FakeRepo>FakeRepo.__new__(FakeRepo)
            else:  # pragma: no cover
                raise NotImplementedError(f'unsupported repo format: {format}')

        obj.ptr = ptr
        obj.ref = ref
        return obj

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
        return _Iter(self)

    def iter_restrict(self, restrict not None):
        """Iterate over a repo's packages while applying a restriction."""
        yield from _IterRestrict(self, restrict)

    def __lt__(self, other):
        if isinstance(other, Repo):
            return C.pkgcraft_repo_cmp(self.ptr, (<Repo>other).ptr) == -1
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, Repo):
            return C.pkgcraft_repo_cmp(self.ptr, (<Repo>other).ptr) <= 0
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, Repo):
            return C.pkgcraft_repo_cmp(self.ptr, (<Repo>other).ptr) == 0
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, Repo):
            return C.pkgcraft_repo_cmp(self.ptr, (<Repo>other).ptr) != 0
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, Repo):
            return C.pkgcraft_repo_cmp(self.ptr, (<Repo>other).ptr) >= 0
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, Repo):
            return C.pkgcraft_repo_cmp(self.ptr, (<Repo>other).ptr) == 1
        return NotImplemented

    def __str__(self):
        # Avoid panics due to pytest coercing objects to strings after failures
        # during __init__().
        if self.ptr is NULL:  # pragma: no cover
            raise ValueError("repo not initialized")
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


cdef class _Iter:
    """Iterator over a repo."""

    def __cinit__(self, Repo r not None):
        self.ptr = C.pkgcraft_repo_iter(r.ptr)

    def __iter__(self):
        return self

    def __next__(self):
        ptr = C.pkgcraft_repo_iter_next(self.ptr)
        if ptr is not NULL:
            return Pkg.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_repo_iter_free(self.ptr)


cdef class _IterRestrict:
    """Iterator that applies a restriction over a repo iterator."""

    def __cinit__(self, Repo repo not None, object obj not None):
        cdef Restrict r = obj if isinstance(obj, Restrict) else Restrict(obj)
        self.ptr = C.pkgcraft_repo_iter_restrict(repo.ptr, r.ptr)

    def __iter__(self):
        return self

    def __next__(self):
        ptr = C.pkgcraft_repo_iter_restrict_next(self.ptr)
        if ptr is not NULL:
            return Pkg.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_repo_iter_restrict_free(self.ptr)
