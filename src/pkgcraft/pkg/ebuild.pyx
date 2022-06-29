from .. cimport pkgcraft_c as C
from ..atom cimport Cpv
from ..error import PkgcraftError


cdef class EbuildPkg(Pkg):
    """Generic ebuild package."""

    @property
    def description(self):
        """Get an ebuild's description."""
        cdef char *c_str
        if self._description is None:
            c_str = C.pkgcraft_ebuild_pkg_description(self._ebuild_pkg)
            self._description = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._description

    @property
    def slot(self):
        """Get an ebuild's slot."""
        cdef char *c_str
        if self._slot is None:
            c_str = C.pkgcraft_ebuild_pkg_slot(self._ebuild_pkg)
            self._slot = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._slot
