cimport cython
from cpython.mem cimport PyMem_Free, PyMem_Malloc

from .. cimport pkgcraft_c as C
from ..config cimport repos_to_dict
from ..pkg cimport Pkg
from ..restrict cimport Restrict
from . cimport Repo

from .. import parse
from ..types import OrderedFrozenSet


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
        """Create a RepoSet from a pointer."""
        obj = <RepoSet>RepoSet.__new__(RepoSet)
        obj.ptr = ptr
        return obj

    def __iter__(self):
        return _Iter(self)

    def iter(self, restrict=None):
        """Iterate over a repo set's packages, optionally applying a restriction."""
        yield from _Iter(self, restrict)

    @property
    def repos(self):
        """Return the set's repos in order."""
        cdef size_t length
        if self._repos is None:
            repos = <C.Repo **>C.pkgcraft_repo_set_repos(self.ptr, &length)
            d = repos_to_dict(repos, length, True)
            C.pkgcraft_repos_free(repos, length)
            self._repos = OrderedFrozenSet(d.values())
        return self._repos

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

    def __contains__(self, obj not None):
        if isinstance(obj, Repo):
            return obj in self.repos
        return any((obj in r) for r in self.repos)

    def __lt__(self, other):
        if isinstance(other, RepoSet):
            return C.pkgcraft_repo_set_cmp(self.ptr, (<RepoSet>other).ptr) == -1
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, RepoSet):
            return C.pkgcraft_repo_set_cmp(self.ptr, (<RepoSet>other).ptr) <= 0
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, RepoSet):
            return C.pkgcraft_repo_set_cmp(self.ptr, (<RepoSet>other).ptr) == 0
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, RepoSet):
            return C.pkgcraft_repo_set_cmp(self.ptr, (<RepoSet>other).ptr) != 0
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, RepoSet):
            return C.pkgcraft_repo_set_cmp(self.ptr, (<RepoSet>other).ptr) >= 0
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, RepoSet):
            return C.pkgcraft_repo_set_cmp(self.ptr, (<RepoSet>other).ptr) == 1
        return NotImplemented

    def __hash__(self):
        return C.pkgcraft_repo_set_hash(self.ptr)

    def __str__(self):
        return str(self.repos)

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __iand__(self, other):
        op = C.RepoSetOp.REPO_SET_OP_AND
        if isinstance(other, RepoSet):
            C.pkgcraft_repo_set_assign_op_set(op, self.ptr, (<RepoSet>other).ptr)
        elif isinstance(other, Repo):
            C.pkgcraft_repo_set_assign_op_repo(op, self.ptr, (<Repo>other).ptr)
        else:
            return NotImplemented

        # force repos refresh
        self._repos = None
        return self

    def __ior__(self, other):
        op = C.RepoSetOp.REPO_SET_OP_OR
        if isinstance(other, RepoSet):
            C.pkgcraft_repo_set_assign_op_set(op, self.ptr, (<RepoSet>other).ptr)
        elif isinstance(other, Repo):
            C.pkgcraft_repo_set_assign_op_repo(op, self.ptr, (<Repo>other).ptr)
        else:
            return NotImplemented

        # force repos refresh
        self._repos = None
        return self

    def __ixor__(self, other):
        op = C.RepoSetOp.REPO_SET_OP_XOR
        if isinstance(other, RepoSet):
            C.pkgcraft_repo_set_assign_op_set(op, self.ptr, (<RepoSet>other).ptr)
        elif isinstance(other, Repo):
            C.pkgcraft_repo_set_assign_op_repo(op, self.ptr, (<Repo>other).ptr)
        else:
            return NotImplemented

        # force repos refresh
        self._repos = None
        return self

    def __isub__(self, other):
        op = C.RepoSetOp.REPO_SET_OP_SUB
        if isinstance(other, RepoSet):
            C.pkgcraft_repo_set_assign_op_set(op, self.ptr, (<RepoSet>other).ptr)
        elif isinstance(other, Repo):
            C.pkgcraft_repo_set_assign_op_repo(op, self.ptr, (<Repo>other).ptr)
        else:
            return NotImplemented

        # force repos refresh
        self._repos = None
        return self

    def __and__(self, other):
        op = C.RepoSetOp.REPO_SET_OP_AND
        if isinstance(other, RepoSet):
            return RepoSet.from_ptr(C.pkgcraft_repo_set_op_set(op, self.ptr, (<RepoSet>other).ptr))
        elif isinstance(other, Repo):
            return RepoSet.from_ptr(C.pkgcraft_repo_set_op_repo(op, self.ptr, (<Repo>other).ptr))
        else:
            return NotImplemented

    def __rand__(self, other):
        return self.__and__(other)

    def __or__(self, other):
        op = C.RepoSetOp.REPO_SET_OP_OR
        if isinstance(other, RepoSet):
            return RepoSet.from_ptr(C.pkgcraft_repo_set_op_set(op, self.ptr, (<RepoSet>other).ptr))
        elif isinstance(other, Repo):
            return RepoSet.from_ptr(C.pkgcraft_repo_set_op_repo(op, self.ptr, (<Repo>other).ptr))
        else:
            return NotImplemented

    def __ror__(self, other):
        return self.__or__(other)

    def __xor__(self, other):
        op = C.RepoSetOp.REPO_SET_OP_XOR
        if isinstance(other, RepoSet):
            return RepoSet.from_ptr(C.pkgcraft_repo_set_op_set(op, self.ptr, (<RepoSet>other).ptr))
        elif isinstance(other, Repo):
            return RepoSet.from_ptr(C.pkgcraft_repo_set_op_repo(op, self.ptr, (<Repo>other).ptr))
        else:
            return NotImplemented

    def __rxor__(self, other):
        return self.__xor__(other)

    def __sub__(self, other):
        op = C.RepoSetOp.REPO_SET_OP_SUB
        if isinstance(other, RepoSet):
            return RepoSet.from_ptr(C.pkgcraft_repo_set_op_set(op, self.ptr, (<RepoSet>other).ptr))
        elif isinstance(other, Repo):
            return RepoSet.from_ptr(C.pkgcraft_repo_set_op_repo(op, self.ptr, (<Repo>other).ptr))
        else:
            return NotImplemented

    def __rsub__(self, other):
        return self.__sub__(other)

    def __dealloc__(self):
        C.pkgcraft_repo_set_free(self.ptr)


cdef class _Iter:
    """Iterator over a repo set, optionally applying a restriction."""

    def __cinit__(self, RepoSet s not None, obj=None):
        cdef C.Restrict *restrict_ptr = NULL
        cdef Restrict r

        if obj is not None:
            r = obj if isinstance(obj, Restrict) else Restrict(obj)
            restrict_ptr = r.ptr

        self.ptr = C.pkgcraft_repo_set_iter(s.ptr, restrict_ptr)

    def __iter__(self):
        return self

    def __next__(self):
        ptr = C.pkgcraft_repo_set_iter_next(self.ptr)
        if ptr is not NULL:
            return Pkg.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_repo_set_iter_free(self.ptr)
