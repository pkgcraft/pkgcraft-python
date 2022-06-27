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
    def __init__(self, str version not None):
        version_bytes = version.encode()
        self._version = C.pkgcraft_version(version_bytes)
        if not self._version:
            raise PkgcraftError

    @staticmethod
    cdef Version from_ref(const C.Version *ver):
        """Create instance from a borrowed pointer."""
        # skip calling __init__()
        obj = <Version>Version.__new__(Version)
        obj._version = <C.Version *>ver
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
        cdef char* c_str = C.pkgcraft_version_revision(self._version)
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
        """Support pickling Version objects."""
        cdef char* c_str = C.pkgcraft_version_str(self._version)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return (Version, (s,))

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
    def __init__(self, str version not None):
        version_bytes = version.encode()
        self._version = C.pkgcraft_version_with_op(version_bytes)
        if not self._version:
            raise PkgcraftError

    def __reduce__(self):
        # pkgcraft doesn't support returning the full version with an operator
        raise NotImplementedError
