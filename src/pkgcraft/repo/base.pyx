import os
from pathlib import Path

from .. cimport C
from .._misc cimport CStringIter, cstring_to_str
from ..dep cimport Cpv, Version
from ..pkg cimport Pkg
from ..restrict cimport Restrict
from . cimport EbuildRepo, FakeRepo

from .. import parse
from ..error import InvalidRepo
from ..types import OrderedFrozenSet


cdef class Repo:
    """Package repo."""

    _format = None

    def __init__(self, path not None, /, id=None, int priority=0):
        """Create a Repo from a path."""
        path = str(path)
        id = str(id) if id is not None else path

        # When called using a subclass try to load that type, otherwise try types in order.
        if self._format is not None:
            ptr = C.pkgcraft_repo_from_format(
                self._format, id.encode(), priority, path.encode(), True)
        else:
            ptr = C.pkgcraft_repo_from_path(id.encode(), priority, path.encode(), True)

        if ptr is NULL:
            raise InvalidRepo

        self.ref = False
        self.ptr = ptr

    @staticmethod
    cdef Repo from_ptr(C.Repo *ptr, bint ref):
        """Create a Repo from a pointer."""
        cdef Repo obj

        format = C.pkgcraft_repo_format(ptr)
        if format == C.RepoFormat.REPO_FORMAT_EBUILD:
            obj = <EbuildRepo>EbuildRepo.__new__(EbuildRepo)
        elif format == C.RepoFormat.REPO_FORMAT_FAKE:
            obj = <FakeRepo>FakeRepo.__new__(FakeRepo)
        else:  # pragma: no cover
            raise NotImplementedError(f'unsupported repo format: {format}')

        obj.ref = ref
        obj.ptr = ptr
        return obj

    @property
    def id(self):
        """Get a repo's id."""
        if self._id is None:
            self._id = cstring_to_str(C.pkgcraft_repo_id(self.ptr))
        return self._id

    @property
    def path(self):
        """Get a repo's path."""
        if self._path is None:
            self._path = Path(cstring_to_str(C.pkgcraft_repo_path(self.ptr)))
        return self._path

    @property
    def categories(self):
        """Get a repo's categories."""
        cdef size_t length
        c_strs = C.pkgcraft_repo_categories(self.ptr, &length)
        return OrderedFrozenSet(CStringIter.create(c_strs, length))

    def packages(self, cat: str):
        """Get a repo's packages for a category."""
        cdef size_t length
        if parse.category(cat):
            c_strs = C.pkgcraft_repo_packages(self.ptr, cat.encode(), &length)
            return OrderedFrozenSet(CStringIter.create(c_strs, length))

    def versions(self, cat: str, pkg: str):
        """Get a repo's versions for a package."""
        cdef size_t length
        if parse.category(cat) and parse.package(pkg):
            c_versions = C.pkgcraft_repo_versions(self.ptr, cat.encode(), pkg.encode(), &length)
            versions = OrderedFrozenSet(Version.from_ptr(c_versions[i]) for i in range(length))
            C.pkgcraft_array_free(<void **>c_versions, length)
            return versions

    def __len__(self):
        return C.pkgcraft_repo_len(self.ptr)

    def __bool__(self):
        return not C.pkgcraft_repo_is_empty(self.ptr)

    def __contains__(self, obj not None):
        if isinstance(obj, os.PathLike):
            return C.pkgcraft_repo_contains_path(self.ptr, str(obj).encode())
        return bool(next(self.iter(obj), None))

    def __getitem__(self, object obj not None):
        try:
            return next(self.iter(obj))
        except StopIteration:
            raise KeyError(obj)

    def __iter__(self):
        return _Iter(self)

    def iter_cpv(self):
        yield from _IterCpv(self)

    def iter(self, restrict=None):
        """Iterate over a repo's packages, optionally applying a restriction."""
        if restrict is None:
            yield from _Iter(self)
        else:
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


cdef class _IterCpv:
    """Iterator over the Cpv objects from a repo."""

    def __cinit__(self, r: Repo):
        self.ptr = C.pkgcraft_repo_iter_cpv(r.ptr)

    def __iter__(self):
        return self

    def __next__(self):
        if ptr := C.pkgcraft_repo_iter_cpv_next(self.ptr):
            return Cpv.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_repo_iter_cpv_free(self.ptr)


cdef class _Iter:
    """Iterator over a repo."""

    def __cinit__(self, r: Repo):
        self.ptr = C.pkgcraft_repo_iter(r.ptr)

    def __iter__(self):
        return self

    def __next__(self):
        if ptr := C.pkgcraft_repo_iter_next(self.ptr):
            return Pkg.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_repo_iter_free(self.ptr)


cdef class _IterRestrict:
    """Iterator that applies a restriction over a repo iterator."""

    def __cinit__(self, repo: Repo, object obj not None):
        cdef Restrict r = obj if isinstance(obj, Restrict) else Restrict(obj)
        self.ptr = C.pkgcraft_repo_iter_restrict(repo.ptr, r.ptr)

    def __iter__(self):
        return self

    def __next__(self):
        if ptr := C.pkgcraft_repo_iter_restrict_next(self.ptr):
            return Pkg.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_repo_iter_restrict_free(self.ptr)
