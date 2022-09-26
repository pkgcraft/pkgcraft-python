from cpython.mem cimport PyMem_Malloc, PyMem_Free

from .. cimport pkgcraft_c as C
from ..config cimport repos_to_dict
from ..pkg cimport EbuildPkg
from ..restrict cimport Restrict
from . cimport Repo
from ..error import IndirectInit, PkgcraftError
from ..restrict import InvalidRestrict


cdef class RepoSet:
    """Ordered repo set."""

    def __init__(self, repos not None):
        cdef size_t length = len(repos)
        cdef C.Repo **array = <C.Repo **> PyMem_Malloc(length * sizeof(C.Repo *))
        if not array:  # pragma: no cover
            raise MemoryError
        for (i, r) in enumerate(repos):
            array[i] = (<Repo?>r)._repo
        self._set = C.pkgcraft_repo_set(array, length)
        PyMem_Free(array)

    def __iter__(self):
        if self._iter is not NULL:
            C.pkgcraft_repo_set_iter_free(self._iter)
        self._iter = C.pkgcraft_repo_set_iter(self._set)
        return self

    def __next__(self):
        # verify __iter__() was called since cython's generated next() method doesn't check
        if self._iter is NULL:
            raise TypeError(f"{self.__class__.__name__!r} object is not an iterator")

        cdef C.PkgFormat format
        cdef C.Pkg *pkg = C.pkgcraft_repo_set_iter_next(self._iter)
        if pkg is not NULL:
            format = C.pkgcraft_pkg_format(pkg)
            if format is C.PkgFormat.EbuildPkg:
                return EbuildPkg.from_ptr(pkg)
            else:  # pragma: no cover
                raise PkgcraftError('unsupported pkg format')
        raise StopIteration

    def iter_restrict(self, restrict not None):
        """Iterate over a repo set's packages while applying a restriction."""
        yield from _RestrictIter.create(self, restrict)

    @property
    def repos(self):
        """Return the set's repos in order."""
        cdef size_t length
        repos = <C.Repo **>C.pkgcraft_repo_set_repos(self._set, &length)
        d = repos_to_dict(repos, length, True)
        C.pkgcraft_repos_free(repos, length)
        # TODO: replace with ordered, immutable set
        return tuple(d.values())

    def __lt__(self, RepoSet other):
        return C.pkgcraft_repo_set_cmp(self._set, other._set) == -1

    def __le__(self, RepoSet other):
        return C.pkgcraft_repo_set_cmp(self._set, other._set) <= 0

    def __eq__(self, RepoSet other):
        return C.pkgcraft_repo_set_cmp(self._set, other._set) == 0

    def __ne__(self, RepoSet other):
        return C.pkgcraft_repo_set_cmp(self._set, other._set) != 0

    def __gt__(self, RepoSet other):
        return C.pkgcraft_repo_set_cmp(self._set, other._set) == 1

    def __ge__(self, RepoSet other):
        return C.pkgcraft_repo_set_cmp(self._set, other._set) >= 0

    def __hash__(self):
        return C.pkgcraft_repo_set_hash(self._set)

    def __str__(self):
        return str(self.repos)

    def __repr__(self):
        cdef size_t addr = <size_t>&self._set
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __bool__(self):
        return not C.pkgcraft_repo_set_is_empty(self._set)

    def __iand__(RepoSet self, other):
        op = C.RepoSetOp.RepoSetAnd
        s = self._set
        if isinstance(other, RepoSet):
            C.pkgcraft_repo_set_assign_op_set(op, s, (<RepoSet>other)._set)
        else:
            C.pkgcraft_repo_set_assign_op_repo(op, s, (<Repo?>other)._repo)
        return self

    def __ior__(RepoSet self, other):
        op = C.RepoSetOp.RepoSetOr
        s = self._set
        if isinstance(other, RepoSet):
            C.pkgcraft_repo_set_assign_op_set(op, s, (<RepoSet>other)._set)
        else:
            C.pkgcraft_repo_set_assign_op_repo(op, s, (<Repo?>other)._repo)
        return self

    def __ixor__(RepoSet self, other):
        op = C.RepoSetOp.RepoSetXor
        s = self._set
        if isinstance(other, RepoSet):
            C.pkgcraft_repo_set_assign_op_set(op, s, (<RepoSet>other)._set)
        else:
            C.pkgcraft_repo_set_assign_op_repo(op, s, (<Repo?>other)._repo)
        return self

    def __isub__(RepoSet self, other):
        op = C.RepoSetOp.RepoSetSub
        s = self._set
        if isinstance(other, RepoSet):
            C.pkgcraft_repo_set_assign_op_set(op, s, (<RepoSet>other)._set)
        else:
            C.pkgcraft_repo_set_assign_op_repo(op, s, (<Repo?>other)._repo)
        return self

    def __and__(RepoSet self, other):
        op = C.RepoSetOp.RepoSetAnd
        obj = <RepoSet>RepoSet.__new__(RepoSet)
        s = self._set
        if isinstance(other, RepoSet):
            s = C.pkgcraft_repo_set_op_set(op, s, (<RepoSet>other)._set)
        else:
            s = C.pkgcraft_repo_set_op_repo(op, s, (<Repo?>other)._repo)
        obj._set = s
        return obj

    def __or__(RepoSet self, other):
        op = C.RepoSetOp.RepoSetOr
        obj = <RepoSet>RepoSet.__new__(RepoSet)
        s = self._set
        if isinstance(other, RepoSet):
            s = C.pkgcraft_repo_set_op_set(op, s, (<RepoSet>other)._set)
        else:
            s = C.pkgcraft_repo_set_op_repo(op, s, (<Repo?>other)._repo)
        obj._set = s
        return obj

    def __xor__(RepoSet self, other):
        op = C.RepoSetOp.RepoSetXor
        obj = <RepoSet>RepoSet.__new__(RepoSet)
        s = self._set
        if isinstance(other, RepoSet):
            s = C.pkgcraft_repo_set_op_set(op, s, (<RepoSet>other)._set)
        else:
            s = C.pkgcraft_repo_set_op_repo(op, s, (<Repo?>other)._repo)
        obj._set = s
        return obj

    def __sub__(RepoSet self, other):
        op = C.RepoSetOp.RepoSetSub
        obj = <RepoSet>RepoSet.__new__(RepoSet)
        s = self._set
        if isinstance(other, RepoSet):
            s = C.pkgcraft_repo_set_op_set(op, s, (<RepoSet>other)._set)
        else:
            s = C.pkgcraft_repo_set_op_repo(op, s, (<Repo?>other)._repo)
        obj._set = s
        return obj

    def __dealloc__(self):
        C.pkgcraft_repo_set_free(self._set)
        C.pkgcraft_repo_set_iter_free(self._iter)


cdef class _RestrictIter:
    """Iterator that applies a restriction over a repo set iterator."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    @staticmethod
    cdef _RestrictIter create(RepoSet s, object obj):
        cdef Restrict r = obj if isinstance(obj, Restrict) else Restrict(obj)
        o = <_RestrictIter>_RestrictIter.__new__(_RestrictIter)
        o._iter = C.pkgcraft_repo_set_restrict_iter(s._set, r._restrict)
        return o

    def __iter__(self):
        return self

    def __next__(self):
        # verify __iter__() was called since cython's generated next() method doesn't check
        if self._iter is NULL:  # pragma: no cover
            raise TypeError(f"{self.__class__.__name__!r} object is not an iterator")

        cdef C.PkgFormat format
        cdef C.Pkg *pkg = C.pkgcraft_repo_set_restrict_iter_next(self._iter)
        if pkg is not NULL:
            format = C.pkgcraft_pkg_format(pkg)
            if format is C.PkgFormat.EbuildPkg:
                return EbuildPkg.from_ptr(pkg)
            else:  # pragma: no cover
                raise PkgcraftError('unsupported pkg format')
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_repo_set_restrict_iter_free(self._iter)
