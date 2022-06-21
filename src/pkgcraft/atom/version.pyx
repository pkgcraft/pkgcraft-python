# SPDX-License-Identifier: MIT
# cython: language_level=3

from .. cimport pkgcraft_c as C
from ..error import PkgcraftError


cdef class Version:
    """Package version parsing.

    >>> from pkgcraft.atom import Version

    Simple version
    >>> v = Version("1")
    >>> v.revision
    '0'

    Revisioned version
    >>> v = Version("1-r2")
    >>> v.revision
    '2'

    Invalid versions
    >>> v = Version("a")
    Traceback (most recent call last):
        ...
    pkgcraft.error.PkgcraftError: parsing failure: invalid version: "a"
      |
    1 | a
      | ^ Expected: ['0' ..= '9']
      |
    >>> v = Version(">1-r2")
    Traceback (most recent call last):
        ...
    pkgcraft.error.PkgcraftError: parsing failure: invalid version: ">1-r2"
      |
    1 | >1-r2
      | ^ Expected: ['0' ..= '9']
      |
    """
    def __init__(self, str version):
        version_bytes = version.encode()
        self._version = C.pkgcraft_version(version_bytes)
        if not self._version:
            raise PkgcraftError

    @staticmethod
    cdef Version borrowed(const C.Version *ver):
        # create instance without calling __init__()
        obj = <_BorrowedVersion>_BorrowedVersion.__new__(_BorrowedVersion)
        obj._version = <C.Version *>ver
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
        cdef char* c_str = C.pkgcraft_version_revision(self._version)
        if c_str:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

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
        cdef char* c_str = C.pkgcraft_version_str(self._version)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __repr__(self):
        cdef size_t addr = <size_t>&self._version
        return f"<Version '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        return C.pkgcraft_version_hash(self._version)

    def __reduce__(self):
        """Support pickling Version objects.

        >>> import pickle
        >>> from pkgcraft.atom import Version
        >>> a = Version('1-r1')
        >>> b = pickle.loads(pickle.dumps(a))
        >>> a == b
        True
        """
        cdef char* c_str = C.pkgcraft_version_str(self._version)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return (Version, (s,))

    # TODO: move to __del__() when migrating to >=cython-3 since it's not
    # supported in <cython-3 for cdef classes:
    # https://github.com/cython/cython/pull/3804
    def __dealloc__(self):
        if self.__class__ is Version:
            C.pkgcraft_version_free(self._version)


cdef class VersionWithOp(Version):
    """Package version with an operator.

    Simple version
    >>> v = VersionWithOp("=1")
    >>> v.revision
    '0'

    Invalid version
    >>> v = VersionWithOp("1-r2")
    Traceback (most recent call last):
        ...
    pkgcraft.error.PkgcraftError: parsing failure: invalid version: "1-r2"
      |
    1 | 1-r2
      | ^ Expected: one of "<", "=", ">", "~"
      |
    """
    def __init__(self, str version):
        version_bytes = version.encode()
        self._version = C.pkgcraft_version_with_op(version_bytes)
        if not self._version:
            raise PkgcraftError


cdef class _BorrowedVersion(Version):
    """Wrapper class that avoids deallocating the borrowed version pointer."""
