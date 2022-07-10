from .. cimport pkgcraft_c as C
from ..repo cimport Repo
from ..atom cimport Cpv
from ..error import PkgcraftError


cdef class Pkg:
    """Generic package."""

    def __init__(self):
        raise PkgcraftError(f"{self.__class__} doesn't support regular creation")

    @property
    def atom(self):
        """Get a package's atom."""
        cdef const C.Atom *cpv = C.pkgcraft_pkg_atom(self._pkg)
        return Cpv.from_ref(cpv)

    @property
    def repo(self):
        """Get a package's repo."""
        cdef const C.Repo *repo = C.pkgcraft_pkg_repo(self._pkg)
        return Repo.from_ref(repo)

    @property
    def eapi(self):
        """Get a package's EAPI."""
        cdef char *c_str = C.pkgcraft_pkg_eapi(self._pkg)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __lt__(self, Pkg other):
        return C.pkgcraft_pkg_cmp(self._pkg, other._pkg) == -1

    def __le__(self, Pkg other):
        return C.pkgcraft_pkg_cmp(self._pkg, other._pkg) <= 0

    def __eq__(self, Pkg other):
        return C.pkgcraft_pkg_cmp(self._pkg, other._pkg) == 0

    def __ne__(self, Pkg other):
        return C.pkgcraft_pkg_cmp(self._pkg, other._pkg) != 0

    def __gt__(self, Pkg other):
        return C.pkgcraft_pkg_cmp(self._pkg, other._pkg) == 1

    def __ge__(self, Pkg other):
        return C.pkgcraft_pkg_cmp(self._pkg, other._pkg) >= 0

    def __repr__(self):
        cdef size_t addr = <size_t>&self._pkg
        name = self.__class__.__name__
        return f"<{name} '{self.atom}' at 0x{addr:0x}>"

    def __hash__(self):
        return C.pkgcraft_pkg_hash(self._pkg)

    def __dealloc__(self):
        C.pkgcraft_pkg_free(self._pkg)
