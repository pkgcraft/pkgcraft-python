from .. cimport pkgcraft_c as C
from ..error import PkgcraftError


cdef class Version:
    """Atom version.

    >>> from pkgcraft.atom import Version

    Simple version
    >>> v = Version("1")
    >>> v.revision
    '0'

    Revisioned version
    >>> v = Version("1-r2")
    >>> v.revision
    '2'
    """
    def __init__(self, str version not None):
        self._version = C.pkgcraft_version(version.encode())
        if not self._version:
            raise PkgcraftError

    @staticmethod
    cdef Version from_ptr(const C.AtomVersion *ver):
        """Create instance from a borrowed pointer."""
        obj = <Version>Version.__new__(Version)
        obj._version = <C.AtomVersion *>ver
        obj._ref = True
        return obj

    @property
    def revision(self):
        """Get a version's revision.

        >>> from pkgcraft.atom import Version
        >>> v = Version("1-r2")
        >>> v.revision
        '2'
        >>> v = Version("1")
        >>> v.revision
        '0'
        """
        cdef char *c_str = C.pkgcraft_version_revision(self._version)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __lt__(self, Version other):
        return C.pkgcraft_version_cmp(self._version, other._version) == -1

    def __le__(self, Version other):
        return C.pkgcraft_version_cmp(self._version, other._version) <= 0

    def __eq__(self, Version other):
        return C.pkgcraft_version_cmp(self._version, other._version) == 0

    def __ne__(self, Version other):
        return C.pkgcraft_version_cmp(self._version, other._version) != 0

    def __gt__(self, Version other):
        return C.pkgcraft_version_cmp(self._version, other._version) == 1

    def __ge__(self, Version other):
        return C.pkgcraft_version_cmp(self._version, other._version) >= 0

    def __str__(self):
        cdef char *c_str = C.pkgcraft_version_str(self._version)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __repr__(self):
        cdef size_t addr = <size_t>&self._version
        return f"<Version '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        if not self._hash:
            self._hash = C.pkgcraft_version_hash(self._version)
        return self._hash

    def __reduce__(self):
        cdef char *c_str = C.pkgcraft_version_str(self._version)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return (self.__class__, (s,))

    # TODO: move to __del__() when migrating to >=cython-3 since it's not
    # supported in <cython-3 for cdef classes:
    # https://github.com/cython/cython/pull/3804
    def __dealloc__(self):
        if not self._ref:
            C.pkgcraft_version_free(self._version)


cdef class VersionWithOp(Version):
    """Atom version with an operator.

    Simple version
    >>> v = VersionWithOp("=1")
    >>> v.revision
    '0'
    """
    def __init__(self, str version not None):
        self._version = C.pkgcraft_version_with_op(version.encode())
        if not self._version:
            raise PkgcraftError
