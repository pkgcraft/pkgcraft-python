from .. cimport pkgcraft_c as C
from ..atom cimport Cpv, Version
from ..eapi cimport Eapi
from ..error cimport _IndirectInit
from ..repo cimport Repo
from ..restrict cimport Restrict
from . cimport EbuildPkg, FakePkg


cdef class Pkg(_IndirectInit):
    """Generic package."""

    @staticmethod
    cdef Pkg from_ptr(C.Pkg *ptr):
        """Create a Pkg from a pointer."""
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
    def cpv(self):
        """Get a package's CPV."""
        return Cpv.from_ptr(C.pkgcraft_pkg_cpv(self.ptr))

    @property
    def eapi(self):
        """Get a package's EAPI."""
        if self._eapi is None:
            self._eapi = Eapi.from_ptr(C.pkgcraft_pkg_eapi(self.ptr))
        return self._eapi

    @property
    def repo(self):
        """Get a package's repo."""
        ptr = C.pkgcraft_pkg_repo(self.ptr)
        return Repo.from_ptr(<C.Repo *>ptr, True)

    @property
    def version(self):
        """Get a package's version."""
        ptr = C.pkgcraft_pkg_version(self.ptr)
        return Version.from_ptr(ptr)

    def matches(self, Restrict r not None):
        """Determine if a restriction matches a package."""
        return C.pkgcraft_pkg_restrict_matches(self.ptr, r.ptr)

    def __lt__(self, other):
        if isinstance(other, Pkg):
            return C.pkgcraft_pkg_cmp(self.ptr, (<Pkg>other).ptr) == -1
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, Pkg):
            return C.pkgcraft_pkg_cmp(self.ptr, (<Pkg>other).ptr) <= 0
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, Pkg):
            return C.pkgcraft_pkg_cmp(self.ptr, (<Pkg>other).ptr) == 0
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, Pkg):
            return C.pkgcraft_pkg_cmp(self.ptr, (<Pkg>other).ptr) != 0
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, Pkg):
            return C.pkgcraft_pkg_cmp(self.ptr, (<Pkg>other).ptr) >= 0
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, Pkg):
            return C.pkgcraft_pkg_cmp(self.ptr, (<Pkg>other).ptr) == 1
        return NotImplemented

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
