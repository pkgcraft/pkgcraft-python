from enum import IntEnum

from .. cimport pkgcraft_c as C
from ..error import InvalidVersion


class Operator(IntEnum):
    Less = C.OPERATOR_LESS
    LessOrEqual = C.OPERATOR_LESS_OR_EQUAL
    Equal = C.OPERATOR_EQUAL
    EqualGlob = C.OPERATOR_EQUAL_GLOB
    Approximate = C.OPERATOR_APPROXIMATE
    GreaterOrEqual = C.OPERATOR_GREATER_OR_EQUAL
    Greater = C.OPERATOR_GREATER

    @staticmethod
    def from_str(str s not None):
        op = C.pkgcraft_version_op_from_str(s.encode())
        if op > 0:
            return Operator(op)
        raise ValueError(f'invalid operator: {s}')

    def __str__(self):
        c_str = C.pkgcraft_version_op_str(self)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __eq__(self, other):
        if isinstance(other, str):
            return str(self) == other
        return int(self) == other


cdef class Version:
    """Package version.

    >>> from pkgcraft.dep import Version

    Simple version
    >>> v = Version('1')
    >>> v.revision is None
    True

    Revisioned version
    >>> v = Version('1-r2')
    >>> v.revision
    '2'

    Invalid version
    >>> Version('1a-1')
    Traceback (most recent call last):
        ...
    pkgcraft.error.InvalidVersion: parsing failure: invalid version: 1a-1
    ...
    """
    def __init__(self, str s not None):
        self.ptr = C.pkgcraft_version_new(s.encode())
        if self.ptr is NULL:
            raise InvalidVersion

    @staticmethod
    cdef Version from_ptr(C.Version *ptr):
        """Convert a Version pointer to a Version object."""
        if ptr is not NULL:
            obj = <Version>Version.__new__(Version)
            obj.ptr = ptr
            return obj
        return None

    @property
    def op(self):
        """Get a version's operator.

        >>> from pkgcraft.dep import Operator, Version, VersionWithOp
        >>> v = Version('1-r2')
        >>> v.op is None
        True
        >>> v = VersionWithOp('>=1')
        >>> v.op is Operator.GreaterOrEqual
        True
        >>> v.op == '>='
        True
        """
        cdef int op = C.pkgcraft_version_op(self.ptr)
        if op > 0:
            return Operator(op)
        return None

    @property
    def base(self):
        """Get a version's base.

        >>> from pkgcraft.dep import Version, VersionWithOp
        >>> v = Version('1-r2')
        >>> v.base
        '1'
        >>> v = VersionWithOp('>=1.2_alpha3')
        >>> v.base
        '1.2_alpha3'
        """
        c_str = C.pkgcraft_version_base(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    @property
    def revision(self):
        """Get a version's revision.

        >>> from pkgcraft.dep import Version
        >>> v = Version('1-r2')
        >>> v.revision
        '2'
        >>> v = Version('1')
        >>> v.revision is None
        True
        >>> v = Version('1-r0')
        >>> v.revision
        '0'
        """
        c_str = C.pkgcraft_version_revision(self.ptr)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    def intersects(self, Version other not None):
        """Determine if two versions intersect.

        >>> from pkgcraft.dep import Version, VersionWithOp
        >>> v1 = VersionWithOp('>1')
        >>> v2 = Version('2-r1')
        >>> v1.intersects(v2) and v2.intersects(v1)
        True
        >>> v1 = VersionWithOp('>1-r1')
        >>> v2 = VersionWithOp('=1-r1')
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
        c_str = C.pkgcraft_version_str(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

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


cdef class VersionWithOp(Version):
    """Package version with an operator.

    >>> v = VersionWithOp('=1')
    >>> v.op == "="
    True

    Missing operator
    >>> VersionWithOp('1')
    Traceback (most recent call last):
        ...
    pkgcraft.error.InvalidVersion: parsing failure: invalid version: 1
    ...

    Invalid operator
    >>> VersionWithOp('^1')
    Traceback (most recent call last):
        ...
    pkgcraft.error.InvalidVersion: parsing failure: invalid version: ^1
    ...
    """
    def __init__(self, str s not None):
        self.ptr = C.pkgcraft_version_with_op(s.encode())
        if self.ptr is NULL:
            raise InvalidVersion

    def __str__(self):
        c_str = C.pkgcraft_version_str_with_op(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s
