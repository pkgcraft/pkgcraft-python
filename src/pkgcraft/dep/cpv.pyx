cimport cython

from .. cimport C
from .._misc cimport cstring_to_str
from ..restrict cimport Restrict
from .cpn cimport Cpn
from .pkg cimport Dep
from .version cimport Version

from ..error import InvalidCpv, PkgcraftError
from .version import Operator


@cython.final
cdef class Cpv:
    """Category and package version object support."""

    def __init__(self, s: str):
        """Create a new Cpv object.

        Valid:

        >>> from pkgcraft.dep import Cpv
        >>> cpv = Cpv('cat/pkg-1-r2')
        >>> cpv.category
        'cat'
        >>> cpv.package
        'pkg'
        >>> str(cpv.version)
        '1-r2'

        Invalid:

        >>> Cpv('>cat/pkg-1')
        Traceback (most recent call last):
            ...
        pkgcraft.error.InvalidCpv: parsing failure: invalid cpv: >cat/pkg-1
        ...
        """
        self.ptr = C.pkgcraft_cpv_new(s.encode())
        if self.ptr is NULL:
            raise InvalidCpv

    @staticmethod
    def parse(s: str, raised=False):
        """Determine if a string is a valid package Cpv.

        This avoids any allocations, only returning the validity status.

        Args:
            s: the string to parse
            raised: if True, raise an exception when invalid

        Returns:
            bool: True if the given string represents a valid Cpv, otherwise False.

        Raises:
            InvalidCpv: on failure if the raised parameter is set to True

        >>> from pkgcraft.dep import Cpv
        >>> Cpv.parse('cat/pkg-1')
        True
        """
        valid = C.pkgcraft_cpv_parse(s.encode()) is not NULL
        if not valid and raised:
            raise InvalidCpv
        return valid

    @staticmethod
    cdef Cpv from_ptr(C.Cpv *ptr):
        """Create a Cpv from a pointer."""
        inst = <Cpv>Cpv.__new__(Cpv)
        inst.ptr = <C.Cpv *>ptr
        return inst

    def with_op(self, op not None):
        """Create a Dep from a Cpv by applying a version operator.

        Args:
            op (str | Operator): the version operator to apply

        Returns:
            Dep: the newly created Dep

        Raises:
            PkgcraftError: for invalid operator arguments

        >>> from pkgcraft.dep import Cpv, Operator
        >>> cpv = Cpv('cat/pkg-1-r2')

        String-based operator

        >>> str(cpv.with_op('>='))
        '>=cat/pkg-1-r2'

        Enum-based operator

        >>> str(cpv.with_op(Operator.Less))
        '<cat/pkg-1-r2'

        Invalid operator

        >>> cpv.with_op(Operator.Approximate)
        Traceback (most recent call last):
            ...
        pkgcraft.error.PkgcraftError: ~ version operator can't be used with a revision
        """
        if isinstance(op, str):
            op = Operator.from_str(op)
        else:
            op = Operator(op)

        if ptr := C.pkgcraft_cpv_with_op(self.ptr, op):
            return Dep.from_ptr(ptr)
        raise PkgcraftError

    @property
    def category(self):
        """Get the category of a Cpv.

        Returns:
            str: the category name

        >>> from pkgcraft.dep import Cpv
        >>> cpv = Cpv('cat/pkg-1-r2')
        >>> cpv.category
        'cat'
        """
        if self._category is None:
            self._category = cstring_to_str(C.pkgcraft_cpv_category(self.ptr))
        return self._category

    @property
    def package(self):
        """Get the package name of a Cpv.

        Returns:
            str: the package name

        >>> from pkgcraft.dep import Cpv
        >>> cpv = Cpv('cat/pkg-1-r2')
        >>> cpv.package
        'pkg'
        """
        if self._package is None:
            self._package = cstring_to_str(C.pkgcraft_cpv_package(self.ptr))
        return self._package

    @property
    def version(self):
        """Get the version of a Cpv.

        Returns:
            Version: the version object

        >>> from pkgcraft.dep import Cpv
        >>> cpv = Cpv('cat/pkg-1-r2')
        >>> str(cpv.version)
        '1-r2'
        """
        if self._version is None:
            ptr = C.pkgcraft_cpv_version(self.ptr)
            self._version = Version.from_ptr(ptr)
        return self._version

    @property
    def revision(self):
        """Get the revision of a Cpv.

        Returns:
            Revision | None: The revision if it exists or None.

        >>> from pkgcraft.dep import Cpv
        >>> cpv = Cpv('cat/pkg-1-r2')
        >>> str(cpv.revision)
        '2'
        >>> cpv = Cpv('cat/pkg-1-r0')
        >>> str(cpv.revision)
        '0'
        >>> cpv = Cpv('cat/pkg-1')
        >>> cpv.revision is None
        True
        """
        return self.version.revision

    @property
    def p(self):
        """Get the package and revision of a Cpv.

        >>> from pkgcraft.dep import Cpv
        >>> cpv = Cpv('cat/pkg-1-r2')
        >>> cpv.p
        'pkg-1'
        """
        return cstring_to_str(C.pkgcraft_cpv_p(self.ptr))

    @property
    def pf(self):
        """Get the package, version, and revision of a Cpv.

        >>> from pkgcraft.dep import Cpv
        >>> cpv = Cpv('cat/pkg-1-r2')
        >>> cpv.pf
        'pkg-1-r2'
        >>> cpv = Cpv('cat/pkg-1-r0')
        >>> cpv.pf
        'pkg-1-r0'
        >>> cpv = Cpv('cat/pkg-1')
        >>> cpv.pf
        'pkg-1'
        """
        return cstring_to_str(C.pkgcraft_cpv_pf(self.ptr))

    @property
    def pr(self):
        """Get the revision of a Cpv.

        >>> from pkgcraft.dep import Cpv
        >>> cpv = Cpv('cat/pkg-1-r2')
        >>> cpv.pr
        'r2'
        >>> cpv = Cpv('cat/pkg-1-r0')
        >>> cpv.pr
        'r0'
        >>> cpv = Cpv('cat/pkg-1')
        >>> cpv.pr
        'r0'
        """
        return cstring_to_str(C.pkgcraft_cpv_pr(self.ptr))

    @property
    def pv(self):
        """Get the version of a Cpv.

        >>> from pkgcraft.dep import Cpv
        >>> cpv = Cpv('cat/pkg-1-r2')
        >>> cpv.pv
        '1'
        >>> cpv = Cpv('cat/pkg-1-r0')
        >>> cpv.pv
        '1'
        >>> cpv = Cpv('cat/pkg-1')
        >>> cpv.pv
        '1'
        """
        return cstring_to_str(C.pkgcraft_cpv_pv(self.ptr))

    @property
    def pvr(self):
        """Get the version and revision of a Cpv.

        >>> from pkgcraft.dep import Cpv
        >>> cpv = Cpv('cat/pkg-1-r2')
        >>> cpv.pvr
        '1-r2'
        >>> cpv = Cpv('cat/pkg-1-r0')
        >>> cpv.pvr
        '1-r0'
        >>> cpv = Cpv('cat/pkg-1')
        >>> cpv.pvr
        '1'
        """
        return cstring_to_str(C.pkgcraft_cpv_pvr(self.ptr))

    @property
    def cpn(self):
        """Get the Cpn of a Cpv.

        >>> from pkgcraft.dep import Cpv
        >>> cpv = Cpv('cat/pkg-1-r2')
        >>> str(cpv.cpn)
        'cat/pkg'
        """
        return Cpn.from_ptr(C.pkgcraft_cpv_cpn(self.ptr))

    def matches(self, r: Restrict):
        """Determine if a restriction matches a Cpv.

        Args:
            r: restriction object to match against

        Returns:
            bool: True if matching, otherwise False.
        """
        return C.pkgcraft_cpv_restrict_matches(self.ptr, r.ptr)

    def intersects(self, other: Cpv | Dep):
        """Determine intersection between two Cpv or Dep objects.

        Args:
            other: object to check for intersection against

        Returns:
            bool: True if intersecting, otherwise False.

        Raises:
            TypeError: for unsupported types

        >>> from pkgcraft.dep import Cpv, Dep
        >>> cpv = Cpv('cat/pkg-2-r1')
        >>> dep = Dep('>cat/pkg-1')
        >>> cpv.intersects(dep) and dep.intersects(cpv)
        True
        """
        if isinstance(other, Cpv):
            return C.pkgcraft_cpv_intersects(self.ptr, (<Cpv>other).ptr)
        elif isinstance(other, Dep):
            return C.pkgcraft_cpv_intersects_dep(self.ptr, (<Dep>other).ptr)
        raise TypeError(f"{other.__class__.__name__!r} unsupported type")

    def __lt__(self, other):
        if isinstance(other, Cpv):
            return C.pkgcraft_cpv_cmp(self.ptr, (<Cpv>other).ptr) == -1
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, Cpv):
            return C.pkgcraft_cpv_cmp(self.ptr, (<Cpv>other).ptr) <= 0
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, Cpv):
            return C.pkgcraft_cpv_cmp(self.ptr, (<Cpv>other).ptr) == 0
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, Cpv):
            return C.pkgcraft_cpv_cmp(self.ptr, (<Cpv>other).ptr) != 0
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, Cpv):
            return C.pkgcraft_cpv_cmp(self.ptr, (<Cpv>other).ptr) >= 0
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, Cpv):
            return C.pkgcraft_cpv_cmp(self.ptr, (<Cpv>other).ptr) == 1
        return NotImplemented

    def __str__(self):
        return cstring_to_str(C.pkgcraft_cpv_str(self.ptr))

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        if not self._hash:
            self._hash = C.pkgcraft_cpv_hash(self.ptr)
        return self._hash

    def __reduce__(self):
        """Support pickling Cpv objects."""
        return self.__class__, (str(self),)

    def __dealloc__(self):
        C.pkgcraft_cpv_free(self.ptr)
