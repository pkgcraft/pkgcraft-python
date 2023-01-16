import os
import random
import string

from cpython.mem cimport PyMem_Free, PyMem_Malloc

from .. cimport pkgcraft_c as C
from . cimport Repo

from ..error import InvalidRepo, PkgcraftError


cdef class FakeRepo(Repo):
    """Fake package repo."""

    format = C.RepoFormat.REPO_FORMAT_FAKE

    def __init__(self, cpvs_or_path=(), id=None, int priority=0):
        if isinstance(cpvs_or_path, (str, os.PathLike)):
            super().__init__(cpvs_or_path, id, priority)
        else:
            # convert cpv strings into C array
            cpvs = [(<str?>s).encode() for s in cpvs_or_path]
            array = <char **>PyMem_Malloc(len(cpvs) * sizeof(char *))
            if not array:  # pragma: no cover
                raise MemoryError
            for i in range(len(cpvs)):
                array[i] = cpvs[i]

            # generate a semi-random repo ID if none was given
            if id is None:
                rand = ''.join(random.choices(string.ascii_letters, k=10))
                id = f'fake-{rand}'

            ptr = C.pkgcraft_repo_fake_new(id.encode(), priority, array, len(cpvs))
            PyMem_Free(array)
            if ptr is NULL:
                raise InvalidRepo

            self.ptr = ptr
            self.ref = False

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
