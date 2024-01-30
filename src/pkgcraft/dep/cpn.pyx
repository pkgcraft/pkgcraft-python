cimport cython

from .. cimport C
from .._misc cimport cstring_to_str
from ..restrict cimport Restrict

from ..error import InvalidCpn


@cython.final
cdef class Cpn:
    """Unversioned package."""

    def __init__(self, s: str):
        """Create a new Cpn object.

        Valid:

        >>> from pkgcraft.dep import Cpn
        >>> cpn = Cpn('cat/pkg')
        >>> cpn.category
        'cat'
        >>> cpn.package
        'pkg'

        Invalid:

        >>> Cpn('>cat/pkg-1')
        Traceback (most recent call last):
            ...
        pkgcraft.error.InvalidCpn: parsing failure: invalid cpn: >cat/pkg-1
        ...
        """
        self.ptr = C.pkgcraft_cpn_new(s.encode())
        if self.ptr is NULL:
            raise InvalidCpn

    @staticmethod
    def parse(s: str, raised=False):
        """Determine if a string is a valid package Cpn.

        This avoids any allocations, only returning the validity status.

        Args:
            s: the string to parse
            raised: if True, raise an exception when invalid

        Returns:
            bool: True if the given string represents a valid Cpn, otherwise False.

        Raises:
            InvalidCpn: on failure if the raised parameter is set to True

        >>> from pkgcraft.dep import Cpn
        >>> Cpn.parse('cat/pkg')
        True
        """
        valid = C.pkgcraft_cpn_parse(s.encode()) is not NULL
        if not valid and raised:
            raise InvalidCpn
        return valid

    @staticmethod
    cdef Cpn from_ptr(C.Cpn *ptr):
        """Create a Cpn from a pointer."""
        inst = <Cpn>Cpn.__new__(Cpn)
        inst.ptr = <C.Cpn *>ptr
        return inst

    @property
    def category(self):
        """Get the category of a Cpn.

        Returns:
            str: the category name

        >>> from pkgcraft.dep import Cpn
        >>> cpn = Cpn('cat/pkg')
        >>> cpn.category
        'cat'
        """
        if self._category is None:
            self._category = cstring_to_str(C.pkgcraft_cpn_category(self.ptr))
        return self._category

    @property
    def package(self):
        """Get the package name of a Cpn.

        Returns:
            str: the package name

        >>> from pkgcraft.dep import Cpn
        >>> cpn = Cpn('cat/pkg')
        >>> cpn.package
        'pkg'
        """
        if self._package is None:
            self._package = cstring_to_str(C.pkgcraft_cpn_package(self.ptr))
        return self._package

    def matches(self, r: Restrict):
        """Determine if a restriction matches a Cpn.

        Args:
            r: restriction object to match against

        Returns:
            bool: True if matching, otherwise False.
        """
        return C.pkgcraft_cpn_restrict_matches(self.ptr, r.ptr)

    def __lt__(self, other):
        if isinstance(other, Cpn):
            return C.pkgcraft_cpn_cmp(self.ptr, (<Cpn>other).ptr) == -1
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, Cpn):
            return C.pkgcraft_cpn_cmp(self.ptr, (<Cpn>other).ptr) <= 0
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, Cpn):
            return C.pkgcraft_cpn_cmp(self.ptr, (<Cpn>other).ptr) == 0
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, Cpn):
            return C.pkgcraft_cpn_cmp(self.ptr, (<Cpn>other).ptr) != 0
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, Cpn):
            return C.pkgcraft_cpn_cmp(self.ptr, (<Cpn>other).ptr) >= 0
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, Cpn):
            return C.pkgcraft_cpn_cmp(self.ptr, (<Cpn>other).ptr) == 1
        return NotImplemented

    def __str__(self):
        return cstring_to_str(C.pkgcraft_cpn_str(self.ptr))

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        if not self._hash:
            self._hash = C.pkgcraft_cpn_hash(self.ptr)
        return self._hash

    def __reduce__(self):
        """Support pickling Cpn objects."""
        return self.__class__, (str(self),)

    def __dealloc__(self):
        C.pkgcraft_cpn_free(self.ptr)
