from cpython.mem cimport PyMem_Malloc, PyMem_Free

from .. cimport pkgcraft_c as C
from ..pkg cimport FakePkg
from . cimport Repo
from ..error import PkgcraftError


cdef class FakeRepo(Repo):
    """Fake package repo."""

    def __init__(self, str id not None, int priority=0, cpvs=()):
        cpvs = [(<str?>s).encode() for s in cpvs]
        array = <char **>PyMem_Malloc(len(cpvs) * sizeof(char *))
        if not array:  # pragma: no cover
            raise MemoryError
        for i in range(len(cpvs)):
            array[i] = cpvs[i]
        repo = C.pkgcraft_repo_fake_new(id.encode(), priority, array, len(cpvs))
        PyMem_Free(array)
        if repo is NULL:
            raise PkgcraftError

        self._repo = repo
        self._ref = False

    @staticmethod
    def from_path(path not None, id=None, int priority=0):
        path = str(path)
        id = str(id) if id is not None else path
        repo = C.pkgcraft_repo_fake_from_path(id.encode(), priority, path.encode())
        if repo is NULL:
            raise PkgcraftError

        return FakeRepo.from_ptr(repo, False)

    def extend(self, cpvs not None):
        """Add packages to an existing repo.

        Note that the repo cannot be included in any RepoSet or Config objects
        otherwise this will raise an error.
        """
        cpvs = [(<str?>s).encode() for s in cpvs]
        array = <char **>PyMem_Malloc(len(cpvs) * sizeof(char *))
        if not array:  # pragma: no cover
            raise MemoryError
        for i in range(len(cpvs)):
            array[i] = cpvs[i]
        repo = C.pkgcraft_repo_fake_extend(self._repo, array, len(cpvs))
        PyMem_Free(array)
        if repo is NULL:
            raise PkgcraftError

    @staticmethod
    cdef FakeRepo from_ptr(const C.Repo *repo, bint ref):
        """Create an instance from a repo pointer."""
        obj = <FakeRepo>FakeRepo.__new__(FakeRepo)
        obj._repo = <C.Repo *>repo
        obj._ref = ref
        return obj

    cdef FakePkg create_pkg(self, C.Pkg *pkg):
        return FakePkg.from_ptr(pkg)
