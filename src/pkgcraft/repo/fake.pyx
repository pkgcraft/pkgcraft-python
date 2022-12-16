from cpython.mem cimport PyMem_Free, PyMem_Malloc

from .. cimport pkgcraft_c as C
from . cimport Repo

from ..error import InvalidRepo, PkgcraftError


cdef class FakeRepo(Repo):
    """Fake package repo."""

    def __init__(self, str id not None, int priority=0, cpvs=()):
        cpvs = [(<str?>s).encode() for s in cpvs]
        array = <char **>PyMem_Malloc(len(cpvs) * sizeof(char *))
        if not array:  # pragma: no cover
            raise MemoryError
        for i in range(len(cpvs)):
            array[i] = cpvs[i]
        ptr = C.pkgcraft_repo_fake_new(id.encode(), priority, array, len(cpvs))
        PyMem_Free(array)
        if ptr is NULL:
            raise InvalidRepo

        self.ptr = ptr
        self.ref = False

    @staticmethod
    def from_path(path not None, id=None, int priority=0):
        path = str(path)
        id = str(id) if id is not None else path
        ptr = C.pkgcraft_repo_fake_from_path(id.encode(), priority, path.encode())
        if ptr is NULL:
            raise InvalidRepo

        return FakeRepo.from_ptr(ptr, False)

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
        repo = C.pkgcraft_repo_fake_extend(self.ptr, array, len(cpvs))
        PyMem_Free(array)
        if repo is NULL:
            raise PkgcraftError
