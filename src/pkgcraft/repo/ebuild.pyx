from .. cimport pkgcraft_c as C
from . cimport Repo


cdef class EbuildRepo(Repo):
    """Ebuild package repo."""

    @property
    def masters(self):
        """Get an ebuild repo's masters."""
        cdef size_t length
        if self._masters is None:
            repos = C.pkgcraft_repo_ebuild_masters(self.ptr, &length)
            self._masters = tuple(EbuildRepo.from_ptr(repos[i], False) for i in range(length))
        return self._masters
