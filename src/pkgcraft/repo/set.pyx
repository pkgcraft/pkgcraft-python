cimport cython
from cpython.mem cimport PyMem_Free, PyMem_Malloc

from .. cimport pkgcraft_c as C
from ..config cimport repos_to_dict
from ..pkg cimport Pkg
from ..restrict cimport Restrict
from . cimport Repo

from .. import parse
from ..error import IndirectInit


@cython.final
cdef class RepoSet:
    """Ordered repo set."""

    def __init__(self, *repos):
        array = <C.Repo **> PyMem_Malloc(len(repos) * sizeof(C.Repo *))
        if not array:  # pragma: no cover
            raise MemoryError
        for (i, r) in enumerate(repos):
            array[i] = (<Repo?>r).ptr
        self.ptr = C.pkgcraft_repo_set_new(array, len(repos))
        PyMem_Free(array)

    @staticmethod
    cdef RepoSet from_ptr(C.RepoSet *ptr):
        """Create an instance from a pointer."""
        obj = <RepoSet>RepoSet.__new__(RepoSet)
        obj.ptr = ptr
        return obj

    def __iter__(self):
        if self.iter_ptr is not NULL:
            C.pkgcraft_repo_set_iter_free(self.iter_ptr)
        self.iter_ptr = C.pkgcraft_repo_set_iter(self.ptr)
        return self

    def __next__(self):
        # verify __iter__() was called since cython's generated next() method doesn't check
        if self.iter_ptr is NULL:
            raise TypeError(f"{self.__class__.__name__!r} object is not an iterator")

        ptr = C.pkgcraft_repo_set_iter_next(self.iter_ptr)
        if ptr is not NULL:
            return Pkg.from_ptr(ptr)
        raise StopIteration

    def iter_restrict(self, restrict not None):
        """Iterate over a repo set's packages while applying a restriction."""
        yield from _RestrictIter.create(self, restrict)

    @property
    def repos(self):
        """Return the set's repos in order."""
        cdef size_t length
        repos = <C.Repo **>C.pkgcraft_repo_set_repos(self.ptr, &length)
        d = repos_to_dict(repos, length, True)
        C.pkgcraft_repos_free(repos, length)
        # TODO: replace with ordered, immutable set
        return tuple(d.values())

    @property
    def categories(self):
        """Get a repo set's categories."""
        cdef size_t length
        cats = C.pkgcraft_repo_set_categories(self.ptr, &length)
        categories = tuple(cats[i].decode() for i in range(length))
        C.pkgcraft_str_array_free(cats, length)
        return categories

    def packages(self, str cat not None):
        """Get a repo set's packages for a category."""
        cdef size_t length
        if parse.category(cat):
            pkgs = C.pkgcraft_repo_set_packages(self.ptr, cat.encode(), &length)
            packages = tuple(pkgs[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(pkgs, length)
            return packages

    def versions(self, str cat not None, str pkg not None):
        """Get a repo set's versions for a package."""
        cdef size_t length
        if parse.category(cat) and parse.package(pkg):
            vers = C.pkgcraft_repo_set_versions(self.ptr, cat.encode(), pkg.encode(), &length)
            versions = tuple(vers[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(vers, length)
            return versions

    def __len__(self):
        return C.pkgcraft_repo_set_len(self.ptr)

    def __bool__(self):
        return not C.pkgcraft_repo_set_is_empty(self.ptr)

    def __lt__(self, RepoSet other):
        return C.pkgcraft_repo_set_cmp(self.ptr, other.ptr) == -1

    def __le__(self, RepoSet other):
        return C.pkgcraft_repo_set_cmp(self.ptr, other.ptr) <= 0

    def __eq__(self, RepoSet other):
        return C.pkgcraft_repo_set_cmp(self.ptr, other.ptr) == 0

    def __ne__(self, RepoSet other):
        return C.pkgcraft_repo_set_cmp(self.ptr, other.ptr) != 0

    def __gt__(self, RepoSet other):
        return C.pkgcraft_repo_set_cmp(self.ptr, other.ptr) == 1

    def __ge__(self, RepoSet other):
        return C.pkgcraft_repo_set_cmp(self.ptr, other.ptr) >= 0

    def __hash__(self):
        return C.pkgcraft_repo_set_hash(self.ptr)

    def __str__(self):
        return str(self.repos)

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __iand__(RepoSet self, other):
        op = C.RepoSetOp.REPO_SET_OP_AND
        if isinstance(other, RepoSet):
            C.pkgcraft_repo_set_assign_op_set(op, self.ptr, (<RepoSet>other).ptr)
        else:
            C.pkgcraft_repo_set_assign_op_repo(op, self.ptr, (<Repo?>other).ptr)
        return self

    def __ior__(RepoSet self, other):
        op = C.RepoSetOp.REPO_SET_OP_OR
        if isinstance(other, RepoSet):
            C.pkgcraft_repo_set_assign_op_set(op, self.ptr, (<RepoSet>other).ptr)
        else:
            C.pkgcraft_repo_set_assign_op_repo(op, self.ptr, (<Repo?>other).ptr)
        return self

    def __ixor__(RepoSet self, other):
        op = C.RepoSetOp.REPO_SET_OP_XOR
        if isinstance(other, RepoSet):
            C.pkgcraft_repo_set_assign_op_set(op, self.ptr, (<RepoSet>other).ptr)
        else:
            C.pkgcraft_repo_set_assign_op_repo(op, self.ptr, (<Repo?>other).ptr)
        return self

    def __isub__(RepoSet self, other):
        op = C.RepoSetOp.REPO_SET_OP_SUB
        if isinstance(other, RepoSet):
            C.pkgcraft_repo_set_assign_op_set(op, self.ptr, (<RepoSet>other).ptr)
        else:
            C.pkgcraft_repo_set_assign_op_repo(op, self.ptr, (<Repo?>other).ptr)
        return self

    def __and__(self, other):
        if isinstance(self, RepoSet):
            ptr = (<RepoSet>self).ptr
        else:
            ptr = (<RepoSet>other).ptr
            other = self

        op = C.RepoSetOp.REPO_SET_OP_AND
        if isinstance(other, RepoSet):
            return RepoSet.from_ptr(C.pkgcraft_repo_set_op_set(op, ptr, (<RepoSet>other).ptr))
        elif isinstance(other, Repo):
            return RepoSet.from_ptr(C.pkgcraft_repo_set_op_repo(op, ptr, (<Repo>other).ptr))
        else:
            return NotImplemented

    def __or__(self, other):
        if isinstance(self, RepoSet):
            ptr = (<RepoSet>self).ptr
        else:
            ptr = (<RepoSet>other).ptr
            other = self

        op = C.RepoSetOp.REPO_SET_OP_OR
        if isinstance(other, RepoSet):
            return RepoSet.from_ptr(C.pkgcraft_repo_set_op_set(op, ptr, (<RepoSet>other).ptr))
        elif isinstance(other, Repo):
            return RepoSet.from_ptr(C.pkgcraft_repo_set_op_repo(op, ptr, (<Repo>other).ptr))
        else:
            return NotImplemented

    def __xor__(self, other):
        if isinstance(self, RepoSet):
            ptr = (<RepoSet>self).ptr
        else:
            ptr = (<RepoSet>other).ptr
            other = self

        op = C.RepoSetOp.REPO_SET_OP_XOR
        if isinstance(other, RepoSet):
            return RepoSet.from_ptr(C.pkgcraft_repo_set_op_set(op, ptr, (<RepoSet>other).ptr))
        elif isinstance(other, Repo):
            return RepoSet.from_ptr(C.pkgcraft_repo_set_op_repo(op, ptr, (<Repo>other).ptr))
        else:
            return NotImplemented

    def __sub__(self, other):
        if isinstance(self, RepoSet):
            ptr = (<RepoSet>self).ptr
        else:
            return NotImplemented

        op = C.RepoSetOp.REPO_SET_OP_SUB
        if isinstance(other, RepoSet):
            return RepoSet.from_ptr(C.pkgcraft_repo_set_op_set(op, ptr, (<RepoSet>other).ptr))
        elif isinstance(other, Repo):
            return RepoSet.from_ptr(C.pkgcraft_repo_set_op_repo(op, ptr, (<Repo>other).ptr))
        else:
            return NotImplemented

    def __dealloc__(self):
        C.pkgcraft_repo_set_free(self.ptr)
        C.pkgcraft_repo_set_iter_free(self.iter_ptr)


cdef class _RestrictIter:
    """Iterator that applies a restriction over a repo set iterator."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    @staticmethod
    cdef _RestrictIter create(RepoSet s, object obj):
        cdef Restrict r = obj if isinstance(obj, Restrict) else Restrict(obj)
        o = <_RestrictIter>_RestrictIter.__new__(_RestrictIter)
        o.ptr = C.pkgcraft_repo_set_restrict_iter(s.ptr, r.ptr)
        return o

    def __iter__(self):
        return self

    def __next__(self):
        # verify __iter__() was called since cython's generated next() method doesn't check
        if self.ptr is NULL:  # pragma: no cover
            raise TypeError(f"{self.__class__.__name__!r} object is not an iterator")

        pkg = C.pkgcraft_repo_set_iter_next(self.ptr)
        if pkg is not NULL:
            return Pkg.from_ptr(pkg)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_repo_set_iter_free(self.ptr)
