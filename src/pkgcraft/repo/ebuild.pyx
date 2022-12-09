from .. cimport pkgcraft_c as C
from . cimport Repo


cdef class EbuildRepo(Repo):
    """Ebuild package repo."""

    @staticmethod
    cdef EbuildRepo from_ptr(const C.Repo *ptr, bint ref):
        """Create an instance from a repo pointer."""
        obj = <EbuildRepo>EbuildRepo.__new__(EbuildRepo)
        obj.ptr = <C.Repo *>ptr
        obj.ref = ref
        return obj

    @property
    def masters(self):
        """Get an ebuild repo's masters."""
        cdef size_t length
        if self._masters is None:
            repos = C.pkgcraft_repo_ebuild_masters(self.ptr, &length)
            self._masters = tuple(EbuildRepo.from_ptr(repos[i], False) for i in range(length))
        return self._masters
