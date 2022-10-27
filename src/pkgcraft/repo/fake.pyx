import os
from cpython.mem cimport PyMem_Malloc, PyMem_Free

from .. cimport pkgcraft_c as C
from ..pkg cimport FakePkg
from . cimport Repo
from ..error import PkgcraftError


cdef class FakeRepo(Repo):
    """Fake package repo."""

    def __init__(self, data not None, id=None, priority=0):
        cdef C.Repo *repo
        path = str(data)

        if os.path.exists(path):
            # data target is a file of atoms
            id = str(id) if id is not None else path
            repo = C.pkgcraft_repo_fake_from_path(id.encode(), int(priority), path.encode())
        elif id is not None:
            # data target is an iterable of atoms
            id = str(id)
            atoms = data.split() if isinstance(data, str) else data
            atoms = [(<str?>s).encode() for s in atoms]
            array = <char **>PyMem_Malloc(len(atoms) * sizeof(char *))
            if not array:  # pragma: no cover
                raise MemoryError
            for (i, atom_b) in enumerate(atoms):
                array[i] = atom_b
            repo = C.pkgcraft_repo_fake_new(id.encode(), int(priority), array, len(atoms))
            PyMem_Free(array)
            if repo is NULL:
                raise PkgcraftError
        else:
            raise AttributeError('missing repo id')

        if repo is NULL:
            raise PkgcraftError

        self._repo = repo
        self._ref = False

    @staticmethod
    cdef FakeRepo from_ptr(const C.Repo *repo, bint ref):
        """Create an instance from a repo pointer."""
        obj = <FakeRepo>FakeRepo.__new__(FakeRepo)
        obj._repo = <C.Repo *>repo
        obj._ref = ref
        return obj

    cdef FakePkg create_pkg(self, C.Pkg *pkg):
        return FakePkg.from_ptr(pkg)
