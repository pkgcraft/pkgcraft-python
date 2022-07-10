from .. cimport pkgcraft_c as C
from .base cimport Pkg
from ..error import PkgcraftError
from ..repo cimport EbuildRepo


cdef class EbuildPkg(Pkg):
    """Generic ebuild package."""

    @property
    def repo(self):
        """Get a package's repo."""
        cdef const C.Repo *repo = C.pkgcraft_pkg_repo(self._pkg)
        return EbuildRepo.from_ref(repo)

    @property
    def ebuild(self):
        """Get a package's ebuild file content."""
        cdef char *c_str = C.pkgcraft_ebuild_pkg_ebuild(self._ebuild_pkg)
        if c_str is NULL:
            raise PkgcraftError
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    @property
    def description(self):
        """Get a package's description."""
        cdef char *c_str
        if self._description is None:
            c_str = C.pkgcraft_ebuild_pkg_description(self._ebuild_pkg)
            self._description = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._description

    @property
    def slot(self):
        """Get a package's slot."""
        cdef char *c_str
        if self._slot is None:
            c_str = C.pkgcraft_ebuild_pkg_slot(self._ebuild_pkg)
            self._slot = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._slot
