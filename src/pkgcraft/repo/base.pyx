import os
from pathlib import Path

cimport cython

from .. cimport C, parse
from .._misc cimport cstring_iter, cstring_to_str
from ..dep cimport Cpv, Version
from ..error cimport Indirect
from ..pkg cimport Pkg
from ..restrict cimport Restrict
from ..types cimport OrderedFrozenSet
from . cimport ConfiguredRepo, EbuildRepo, FakeRepo

from ..error import InvalidRepo, PkgcraftError


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
    cdef Repo from_ptr(C.Repo *ptr, bint ref=False):
        """Create a Repo from a pointer."""
        cdef Repo inst

        format = C.pkgcraft_repo_format(ptr)
        if format == C.RepoFormat.REPO_FORMAT_EBUILD:
            inst = <EbuildRepo>EbuildRepo.__new__(EbuildRepo)
        elif format == C.RepoFormat.REPO_FORMAT_CONFIGURED:
            inst = <ConfiguredRepo>ConfiguredRepo.__new__(ConfiguredRepo)
        elif format == C.RepoFormat.REPO_FORMAT_FAKE:
            inst = <FakeRepo>FakeRepo.__new__(FakeRepo)
        else:  # pragma: no cover
            raise NotImplementedError(f'unsupported repo format: {format}')

        inst.ref = ref
        inst.ptr = ptr
        return inst

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
        return OrderedFrozenSet(cstring_iter(c_strs, length))

    def packages(self, cat: str):
        """Get a repo's packages for a category."""
        cdef size_t length
        if parse.category(cat):
            c_strs = C.pkgcraft_repo_packages(self.ptr, cat.encode(), &length)
            return OrderedFrozenSet(cstring_iter(c_strs, length))

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
        return _Iter.create(self)

    def iter_cpv(self):
        return _IterCpv.create(self)

    def iter(self, restrict=None):
        """Iterate over a repo's packages, optionally applying a restriction."""
        if restrict is None:
            return _Iter.create(self)
        else:
            return _IterRestrict.create(self, restrict)

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


@cython.internal
cdef class _IterCpv(Indirect):
    """Iterator over the Cpv objects from a repo."""

    cdef C.RepoIterCpv *ptr

    @staticmethod
    cdef _IterCpv create(Repo r):
        inst = <_IterCpv>_IterCpv.__new__(_IterCpv)
        if ptr := C.pkgcraft_repo_iter_cpv(r.ptr):
            inst.ptr = ptr
            return inst
        raise PkgcraftError

    def __iter__(self):
        return self

    def __next__(self):
        if ptr := C.pkgcraft_repo_iter_cpv_next(self.ptr):
            return Cpv.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_repo_iter_cpv_free(self.ptr)


@cython.internal
cdef class _Iter(Indirect):
    """Iterator over a repo."""

    cdef C.RepoIter *ptr

    @staticmethod
    cdef _Iter create(Repo r):
        inst = <_Iter>_Iter.__new__(_Iter)
        if ptr := C.pkgcraft_repo_iter(r.ptr):
            inst.ptr = ptr
            return inst
        raise PkgcraftError

    def __iter__(self):
        return self

    def __next__(self):
        if ptr := C.pkgcraft_repo_iter_next(self.ptr):
            return Pkg.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_repo_iter_free(self.ptr)


@cython.internal
cdef class _IterRestrict(Indirect):
    """Iterator that applies a restriction over a repo iterator."""

    cdef C.RepoIterRestrict *ptr

    @staticmethod
    cdef _IterRestrict create(Repo repo, object obj):
        cdef Restrict r = obj if isinstance(obj, Restrict) else Restrict(obj)
        inst = <_IterRestrict>_IterRestrict.__new__(_IterRestrict)
        if ptr := C.pkgcraft_repo_iter_restrict(repo.ptr, r.ptr):
            inst.ptr = ptr
            return inst
        raise PkgcraftError

    def __iter__(self):
        return self

    def __next__(self):
        if ptr := C.pkgcraft_repo_iter_restrict_next(self.ptr):
            return Pkg.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_repo_iter_restrict_free(self.ptr)
