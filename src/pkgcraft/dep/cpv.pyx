cimport cython

from .. cimport C
from .._misc cimport cstring_to_str
from ..restrict cimport Restrict
from . cimport Dep
from .version cimport Version

from ..error import InvalidCpv


@cython.final
cdef class Cpv:
    """CPV string parsing.

    >>> from pkgcraft.dep import Cpv

    Valid CPV
    >>> cpv = Cpv('cat/pkg-1-r2')
    >>> cpv.category
    'cat'
    >>> cpv.package
    'pkg'
    >>> str(cpv.version)
    '1-r2'

    Invalid CPV
    >>> Cpv('>cat/pkg-1')
    Traceback (most recent call last):
        ...
    pkgcraft.error.InvalidCpv: parsing failure: invalid cpv: >cat/pkg-1
    ...
    """
    def __init__(self, str s not None):
        self.ptr = C.pkgcraft_cpv_new(s.encode())
        if self.ptr is NULL:
            raise InvalidCpv

    @staticmethod
    cdef Cpv from_ptr(C.Cpv *ptr):
        """Create a Cpv from a pointer."""
        obj = <Cpv>Cpv.__new__(Cpv)
        obj.ptr = <C.Cpv *>ptr
        return obj

    @property
    def category(self):
        """Get the category of a Cpv.

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

        >>> from pkgcraft.dep import Cpv
        >>> cpv = Cpv('cat/pkg-1-r2')
        >>> cpv.revision
        '2'
        >>> cpv = Cpv('cat/pkg-1-r0')
        >>> cpv.revision
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
        """Get the category and package of a Cpv.

        >>> from pkgcraft.dep import Cpv
        >>> cpv = Cpv('cat/pkg-1-r2')
        >>> cpv.cpn
        'cat/pkg'
        """
        return cstring_to_str(C.pkgcraft_cpv_cpn(self.ptr))

    def matches(self, Restrict r not None):
        """Determine if a restriction matches a Cpv."""
        return C.pkgcraft_cpv_restrict_matches(self.ptr, r.ptr)

    def intersects(self, other):
        """Determine intersection between two Cpv or Dep objects.

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
        else:
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
