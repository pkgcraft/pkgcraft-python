from .. cimport pkgcraft_c as C
from . cimport Repo


cdef class EbuildRepo(Repo):
    """Ebuild package repo."""

    format = C.RepoFormat.REPO_FORMAT_EBUILD

    @property
    def masters(self):
        """Get an ebuild repo's masters."""
        cdef size_t length
        if self._masters is None:
            repos = C.pkgcraft_repo_ebuild_masters(self.ptr, &length)
            self._masters = tuple(EbuildRepo.from_ptr(repos[i], False) for i in range(length))
        return self._masters

    @property
    def eapi(self):
        """Get an ebuild repo's EAPI."""
        if self._eapi is None:
            self._eapi = Eapi.from_ptr(C.pkgcraft_repo_ebuild_eapi(self.ptr))
        return self._eapi
