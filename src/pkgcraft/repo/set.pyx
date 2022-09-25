from cpython.mem cimport PyMem_Malloc, PyMem_Free

from .. cimport pkgcraft_c as C
from ..pkg cimport EbuildPkg
from ..restrict cimport Restrict
from . cimport Repo
from ..error import PkgcraftError
from ..restrict import InvalidRestrict


cdef class RepoSet:
    """Ordered repo set."""

    def __cinit__(self, repos not None):
        cdef size_t length = len(repos)
        cdef C.Repo **array = <C.Repo **> PyMem_Malloc(length * sizeof(C.Repo *))
        if not array:
            raise MemoryError
        for (i, r) in enumerate(repos):
            array[i] = (<Repo?>r)._repo
        self._repo_set = C.pkgcraft_repo_set(array, length)
        PyMem_Free(array)

    def __iter__(self):
        if self._iter is not NULL:
            C.pkgcraft_repo_set_iter_free(self._iter)
        self._iter = C.pkgcraft_repo_set_iter(self._repo_set)
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
            else:
                raise PkgcraftError('unsupported pkg format')
        raise StopIteration

    def iter_restrict(self, restrict not None):
        """Iterate over a repo set's packages while applying a restriction."""
        yield from _RestrictIter.create(self, restrict)


cdef class _RestrictIter:
    """Iterator that applies a restriction over a repo set iterator."""

    def __init__(self):  # pragma: no cover
        raise RuntimeError(f"{self.__class__.__name__} class doesn't support manual construction")

    @staticmethod
    cdef _RestrictIter create(RepoSet repo_set, object obj):
        cdef Restrict r = obj if isinstance(obj, Restrict) else Restrict(obj)
        o = <_RestrictIter>_RestrictIter.__new__(_RestrictIter)
        o._iter = C.pkgcraft_repo_set_restrict_iter(repo_set._repo_set, r._restrict)
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
            else:
                raise PkgcraftError('unsupported pkg format')
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_repo_set_restrict_iter_free(self._iter)
