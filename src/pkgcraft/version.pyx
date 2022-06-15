# SPDX-License-Identifier: MIT
# cython: language_level=3

from . cimport pkgcraft_c as C
from .error import PkgcraftError


cdef class Version:
    """Package version parsing.

    >>> from pkgcraft import Version

    Simple version
    >>> v = Version("1")
    >>> v.revision
    '0'

    Revisioned version
    >>> v = Version("1-r2")
    >>> v.revision
    '2'

    Invalid version
    >>> v = Version("a")
    Traceback (most recent call last):
        ...
    pkgcraft.error.PkgcraftError: parsing failure: invalid version: "a"
      |
    1 | a
      | ^ Expected: ['0' ..= '9']
      |
    """

    cdef C.Version *_version

    def __cinit__(self, str version):
        self._version = C.pkgcraft_version(version.encode())
        if not self._version:
            raise PkgcraftError

    @property
    def revision(self):
        """Get a version's revision.

        >>> from pkgcraft import Version
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
        else:
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
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        return C.pkgcraft_version_hash(self._version)

    def __reduce__(self):
        """Support pickling Version objects.

        >>> import pickle
        >>> from pkgcraft import Version
        >>> a = Version('1-r1')
        >>> b = pickle.loads(pickle.dumps(a))
        >>> a == b
        True
        """
        cdef char* c_str = C.pkgcraft_version_str(self._version)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return (Version, (s,))

    def __dealloc__(self):
        C.pkgcraft_version_free(self._version)
