from .. cimport pkgcraft_c as C
from . cimport Pkg
from ..repo cimport FakeRepo
from ..error import IndirectInit


cdef class FakePkg(Pkg):
    """Generic ebuild package."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    @staticmethod
    cdef FakePkg from_ptr(C.Pkg *pkg):
        """Create an instance from a Pkg pointer."""
        obj = <FakePkg>FakePkg.__new__(FakePkg)
        obj._pkg = <C.Pkg *>pkg
        return obj

    @property
    def repo(self):
        """Get a package's repo."""
        repo = C.pkgcraft_pkg_repo(self._pkg)
        return FakeRepo.from_ptr(repo, True)
