from enum import IntEnum

from .. cimport C
from .._misc cimport SENTINEL, cstring_to_str

from ..error import InvalidVersion, PkgcraftError


class Operator(IntEnum):
    Less = C.OPERATOR_LESS
    LessOrEqual = C.OPERATOR_LESS_OR_EQUAL
    Equal = C.OPERATOR_EQUAL
    EqualGlob = C.OPERATOR_EQUAL_GLOB
    Approximate = C.OPERATOR_APPROXIMATE
    GreaterOrEqual = C.OPERATOR_GREATER_OR_EQUAL
    Greater = C.OPERATOR_GREATER

    @staticmethod
    def from_str(s: str):
        if op := C.pkgcraft_version_op_from_str(s.encode()):
            return Operator(op)
        raise ValueError(f'invalid operator: {s}')

    def __str__(self):
        return cstring_to_str(C.pkgcraft_version_op_str(self))

    def __eq__(self, other):
        if isinstance(other, str):
            return str(self) == other
        return int(self) == other


cdef class Revision:
    """Package revision."""

    def __init__(self, s: str):
        self.ptr = C.pkgcraft_revision_new(s.encode())
        if self.ptr is NULL:
            raise InvalidVersion

    @staticmethod
    cdef Revision from_ptr(C.Revision *ptr):
        """Convert a Revision pointer to a Revision object."""
        inst = <Revision>Revision.__new__(Revision)
        inst.ptr = ptr
        return inst

    def __bool__(self):
        return bool(str(self))

    def __lt__(self, other):
        if isinstance(other, Revision):
            return C.pkgcraft_revision_cmp(self.ptr, (<Revision>other).ptr) == -1
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, Revision):
            return C.pkgcraft_revision_cmp(self.ptr, (<Revision>other).ptr) <= 0
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, Revision):
            return C.pkgcraft_revision_cmp(self.ptr, (<Revision>other).ptr) == 0
        elif other is None:
            return not self
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, Revision):
            return C.pkgcraft_revision_cmp(self.ptr, (<Revision>other).ptr) != 0
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, Revision):
            return C.pkgcraft_revision_cmp(self.ptr, (<Revision>other).ptr) >= 0
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, Revision):
            return C.pkgcraft_revision_cmp(self.ptr, (<Revision>other).ptr) == 1
        return NotImplemented

    def __str__(self):
        return cstring_to_str(C.pkgcraft_revision_str(self.ptr))

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        if not self._hash:
            self._hash = C.pkgcraft_revision_hash(self.ptr)
        return self._hash

    def __reduce__(self):
        return self.__class__, (str(self),)

    def __dealloc__(self):
        C.pkgcraft_revision_free(self.ptr)


cdef class Version:
    """Package version."""

    def __cinit__(self):
        self._revision = SENTINEL

    def __init__(self, s: str):
        """Create a new package version.

        Simple version:

        >>> from pkgcraft.dep import Operator, Version
        >>> v = Version('1')
        >>> v.revision is None
        True

        Revisioned version:

        >>> v = Version('1-r2')
        >>> str(v.revision)
        '2'

        Version with operator:

        >>> v = Version('>=1.2')
        >>> v.op is Operator.GreaterOrEqual
        True
        >>> v.op == '>='
        True

        Invalid version:

        >>> Version('1a-1')
        Traceback (most recent call last):
            ...
        pkgcraft.error.InvalidVersion: parsing failure: invalid version: 1a-1
        ...
        """
        self.ptr = C.pkgcraft_version_new(s.encode())
        if self.ptr is NULL:
            raise InvalidVersion

    @staticmethod
    def parse(s: str, raised=False):
        """Determine if a string is a valid package version.

        This avoids any string allocations, only returning the validity status.

        Args:
            s: the string to parse
            raised: if True, raise an exception when invalid

        Returns:
            bool: True if the given string represents a valid version, otherwise False.

        Raises:
            InvalidVersion: on failure if the raised parameter is set to True

        >>> from pkgcraft.dep import Version
        >>> Version.parse('1-r2')
        True
        """
        valid = C.pkgcraft_version_parse(s.encode()) is not NULL
        if not valid and raised:
            raise InvalidVersion
        return valid

    @staticmethod
    cdef Version from_ptr(C.Version *ptr):
        """Convert a Version pointer to a Version object."""
        inst = <Version>Version.__new__(Version)
        inst.ptr = ptr
        return inst

    def with_op(self, op not None):
        """Potentially create a new Version by applying an operator.

        Args:
            op (str | Operator): the operator to apply

        Returns:
            Version: the newly created Version (or the original object if no changes were made)

        Raises:
            PkgcraftError: for invalid operator arguments

        >>> from pkgcraft.dep import Version, Operator
        >>> ver = Version('1-r2')

        String-based operator

        >>> str(ver.with_op('>='))
        '>=1-r2'

        Enum-based operator

        >>> str(ver.with_op(Operator.Less))
        '<1-r2'

        Invalid operator

        >>> ver.with_op(Operator.Approximate)
        Traceback (most recent call last):
            ...
        pkgcraft.error.PkgcraftError: ~ version operator can't be used with a revision

        Applying the existing operator returns the original Version

        >>> v1 = Version('>1-r2')
        >>> v2 = v1.with_op(">")
        >>> v1 is v2
        True
        """
        if isinstance(op, str):
            op = Operator.from_str(op)
        else:
            op = Operator(op)

        ptr = C.pkgcraft_version_with_op(self.ptr, op)
        if ptr is NULL:
            raise PkgcraftError
        elif ptr != self.ptr:
            return Version.from_ptr(ptr)
        return self

    @property
    def op(self):
        """Get a version's operator.

        >>> from pkgcraft.dep import Operator, Version
        >>> v = Version('1-r2')
        >>> v.op is None
        True
        >>> v = Version('>=1')
        >>> v.op is Operator.GreaterOrEqual
        True
        >>> v.op == '>='
        True
        """
        if op := C.pkgcraft_version_op(self.ptr):
            return Operator(op)
        return None

    @property
    def base(self):
        """Get a version's base.

        >>> from pkgcraft.dep import Version
        >>> v = Version('1-r2')
        >>> v.base
        '1'
        >>> v = Version('>=1.2_alpha3')
        >>> v.base
        '1.2_alpha3'
        """
        return cstring_to_str(C.pkgcraft_version_base(self.ptr))

    @property
    def revision(self):
        """Get a version's revision.

        >>> from pkgcraft.dep import Version
        >>> v = Version('1-r2')
        >>> str(v.revision)
        '2'
        >>> v = Version('1')
        >>> v.revision is None
        True
        >>> v = Version('1-r0')
        >>> str(v.revision)
        '0'
        """
        if self._revision is SENTINEL:
            ptr = C.pkgcraft_version_revision(self.ptr)
            self._revision = Revision.from_ptr(ptr) if ptr is not NULL else None
        return self._revision

    def intersects(self, other: Version):
        """Determine if two versions intersect.

        >>> from pkgcraft.dep import Version
        >>> v1 = Version('>1')
        >>> v2 = Version('2-r1')
        >>> v1.intersects(v2) and v2.intersects(v1)
        True
        >>> v1 = Version('>1-r1')
        >>> v2 = Version('=1-r1')
        >>> v1.intersects(v2) or v2.intersects(v1)
        False
        """
        return C.pkgcraft_version_intersects(self.ptr, other.ptr)

    def __lt__(self, other):
        if isinstance(other, Version):
            return C.pkgcraft_version_cmp(self.ptr, (<Version>other).ptr) == -1
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, Version):
            return C.pkgcraft_version_cmp(self.ptr, (<Version>other).ptr) <= 0
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, Version):
            return C.pkgcraft_version_cmp(self.ptr, (<Version>other).ptr) == 0
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, Version):
            return C.pkgcraft_version_cmp(self.ptr, (<Version>other).ptr) != 0
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, Version):
            return C.pkgcraft_version_cmp(self.ptr, (<Version>other).ptr) >= 0
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, Version):
            return C.pkgcraft_version_cmp(self.ptr, (<Version>other).ptr) == 1
        return NotImplemented

    def __str__(self):
        return cstring_to_str(C.pkgcraft_version_str(self.ptr))

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        if not self._hash:
            self._hash = C.pkgcraft_version_hash(self.ptr)
        return self._hash

    def __reduce__(self):
        return self.__class__, (str(self),)

    def __dealloc__(self):
        C.pkgcraft_version_free(self.ptr)
