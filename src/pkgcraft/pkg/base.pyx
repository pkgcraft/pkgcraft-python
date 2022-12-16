from .. cimport pkgcraft_c as C
from ..atom cimport Cpv, Version
from ..repo cimport Repo
from ..restrict cimport Restrict
from . cimport EbuildPkg, FakePkg
from ..eapi import EAPIS
from ..error import IndirectInit


cdef class Pkg:
    """Generic package."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    @staticmethod
    cdef Pkg from_ptr(C.Pkg *ptr):
        """Convert a pkg pointer to a pkg object."""
        cdef Pkg obj

        format = C.pkgcraft_pkg_format(ptr)
        if format == C.PkgFormat.PKG_FORMAT_EBUILD:
            obj = <EbuildPkg>EbuildPkg.__new__(EbuildPkg)
        elif format == C.PkgFormat.PKG_FORMAT_FAKE:
            obj = <FakePkg>FakePkg.__new__(FakePkg)
        else:  # pragma: no cover
            raise NotImplementedError(f'unsupported pkg format: {format}')

        obj.ptr = ptr
        return obj

    @property
    def atom(self):
        """Get a package's atom."""
        cpv = C.pkgcraft_pkg_atom(self.ptr)
        return Cpv.from_ptr(cpv)

    @property
    def eapi(self):
        """Get a package's EAPI."""
        eapi = C.pkgcraft_pkg_eapi(self.ptr)
        c_str = C.pkgcraft_eapi_as_str(eapi)
        id = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return EAPIS[id]

    @property
    def repo(self):
        """Get a package's repo."""
        repo = C.pkgcraft_pkg_repo(self.ptr)
        return Repo.from_ptr(<C.Repo *>repo, True)

    @property
    def version(self):
        """Get a package's version."""
        version = C.pkgcraft_pkg_version(self.ptr)
        return Version.from_ptr(version)

    def matches(self, Restrict r):
        """Determine if a restriction matches a package."""
        return C.pkgcraft_pkg_restrict_matches(self.ptr, r.ptr)

    def __lt__(self, Pkg other):
        return C.pkgcraft_pkg_cmp(self.ptr, other.ptr) == -1

    def __le__(self, Pkg other):
        return C.pkgcraft_pkg_cmp(self.ptr, other.ptr) <= 0

    def __eq__(self, Pkg other):
        return C.pkgcraft_pkg_cmp(self.ptr, other.ptr) == 0

    def __ne__(self, Pkg other):
        return C.pkgcraft_pkg_cmp(self.ptr, other.ptr) != 0

    def __gt__(self, Pkg other):
        return C.pkgcraft_pkg_cmp(self.ptr, other.ptr) == 1

    def __ge__(self, Pkg other):
        return C.pkgcraft_pkg_cmp(self.ptr, other.ptr) >= 0

    def __str__(self):
        c_str = C.pkgcraft_pkg_str(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        if not self._hash:
            self._hash = C.pkgcraft_pkg_hash(self.ptr)
        return self._hash

    def __dealloc__(self):
        C.pkgcraft_pkg_free(self.ptr)
