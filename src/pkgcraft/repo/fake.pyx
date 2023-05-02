import os
import random
import string

from .. cimport C
from .._misc cimport CStringArray
from . cimport Repo

from ..error import InvalidRepo, PkgcraftError


cdef class FakeRepo(Repo):
    """Fake package repo."""

    format = C.RepoFormat.REPO_FORMAT_FAKE

    def __init__(self, cpvs_or_path=(), id=None, int priority=0):
        if isinstance(cpvs_or_path, (str, os.PathLike)):
            super().__init__(cpvs_or_path, id, priority)
        else:
            # generate a semi-random repo ID if none was given
            if id is None:
                rand = ''.join(random.choices(string.ascii_letters, k=10))
                id = f'fake-{rand}'

            array = CStringArray(cpvs_or_path)
            ptr = C.pkgcraft_repo_fake_new(id.encode(), priority, array.ptr, len(array))
            if ptr is NULL:
                raise InvalidRepo

            self.ptr = ptr
            self.ref = False

    def extend(self, cpvs not None):
        """Add packages to an existing repo.

        Note that the repo cannot be included in any RepoSet or Config objects
        otherwise this will raise an error.
        """
        array = CStringArray(cpvs)
        repo = C.pkgcraft_repo_fake_extend(self.ptr, array.ptr, len(array))
        if repo is NULL:
            raise PkgcraftError
