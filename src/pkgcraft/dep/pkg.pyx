import functools
from enum import IntEnum

cimport cython

from .. cimport pkgcraft_c as C
from .._misc cimport SENTINEL
from ..eapi cimport eapi_from_obj
from ..restrict cimport Restrict
from . cimport Cpv
from .version cimport Version

from ..eapi import EAPI_LATEST
from ..error import InvalidDep


# TODO: merge with Dep.cached function when cython bug is fixed
# https://github.com/cython/cython/issues/1434
@functools.lru_cache(maxsize=10000)
def _cached_dep(cls, dep, eapi=None):
    return cls(dep, eapi)


class Blocker(IntEnum):
    Strong = C.BLOCKER_STRONG
    Weak = C.BLOCKER_WEAK

    @staticmethod
    def from_str(str s not None):
        blocker = C.pkgcraft_dep_blocker_from_str(s.encode())
        if blocker > 0:
            return Blocker(blocker)
        raise ValueError(f'invalid blocker: {s}')

    def __str__(self):
        c_str = C.pkgcraft_dep_blocker_str(self)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __eq__(self, other):
        if isinstance(other, str):
            return str(self) == other
        return int(self) == other


class SlotOperator(IntEnum):
    Equal = C.SLOT_OPERATOR_EQUAL
    Star = C.SLOT_OPERATOR_STAR

    @staticmethod
    def from_str(str s not None):
        slot_op = C.pkgcraft_dep_slot_op_from_str(s.encode())
        if slot_op > 0:
            return SlotOperator(slot_op)
        raise ValueError(f'invalid slot operator: {s}')

    def __str__(self):
        c_str = C.pkgcraft_dep_slot_op_str(self)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __eq__(self, other):
        if isinstance(other, str):
            return str(self) == other
        return int(self) == other


@cython.final
cdef class Dep:
    """Package dependency parsing.

    >>> from pkgcraft.dep import Dep

    Unversioned package dependency
    >>> dep = Dep('cat/pkg')
    >>> dep.category
    'cat'
    >>> dep.package
    'pkg'

    Complex package dependency
    >>> dep = Dep('=cat/pkg-1-r2:0/2[a,b]::repo')
    >>> dep.category
    'cat'
    >>> dep.package
    'pkg'
    >>> str(dep.version)
    '1-r2'
    >>> dep.revision
    '2'
    >>> dep.slot
    '0'
    >>> dep.subslot
    '2'
    >>> dep.use
    ('a', 'b')
    >>> dep.repo
    'repo'

    Invalid package dependency
    >>> Dep('cat/pkg-1')
    Traceback (most recent call last):
        ...
    pkgcraft.error.InvalidDep: parsing failure: invalid dep: cat/pkg-1
    ...
    """
    def __cinit__(self):
        self._version = SENTINEL
        self._use = SENTINEL
        self.eapi = EAPI_LATEST

    def __init__(self, str s not None, eapi=None):
        if eapi is not None:
            self.eapi = eapi_from_obj(eapi)

        self.ptr = C.pkgcraft_dep_new(s.encode(), self.eapi.ptr)
        if self.ptr is NULL:
            raise InvalidDep

    @staticmethod
    cdef Dep from_ptr(C.Dep *ptr):
        """Create an Dep from a pointer."""
        obj = <Dep>Dep.__new__(Dep)
        obj.ptr = <C.Dep *>ptr
        return obj

    @classmethod
    def cached(cls, str s not None, eapi=None):
        """Return a cached Dep if one exists, otherwise return a new instance."""
        return _cached_dep(cls, s, eapi)

    @property
    def blocker(self):
        """Get the blocker of a package dependency.

        >>> from pkgcraft.dep import Blocker, Dep
        >>> dep = Dep('cat/pkg')
        >>> dep.blocker is None
        True
        >>> dep = Dep('!cat/pkg')
        >>> dep.blocker is Blocker.Weak
        True
        >>> dep = Dep('!!cat/pkg')
        >>> dep.blocker is Blocker.Strong
        True
        """
        cdef int blocker = C.pkgcraft_dep_blocker(self.ptr)
        if blocker > 0:
            return Blocker(blocker)
        return None

    @property
    def category(self):
        """Get the category of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> dep.category
        'cat'
        """
        if self._category is None:
            c_str = C.pkgcraft_dep_category(self.ptr)
            self._category = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._category

    @property
    def package(self):
        """Get the package name of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> dep.package
        'pkg'
        """
        if self._package is None:
            c_str = C.pkgcraft_dep_package(self.ptr)
            self._package = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._package

    @property
    def version(self):
        """Get the version of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> str(dep.version)
        '1-r2'
        >>> dep = Dep('cat/pkg')
        >>> dep.version is None
        True
        """
        if self._version is SENTINEL:
            ptr = C.pkgcraft_dep_version(self.ptr)
            self._version = Version.from_ptr(ptr)
        return self._version

    @property
    def revision(self):
        """Get the revision of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> dep.revision
        '2'
        >>> dep = Dep('=cat/pkg-1-r0')
        >>> dep.revision
        '0'
        >>> dep = Dep('cat/pkg')
        >>> dep.revision is None
        True
        """
        version = self.version
        if version is not None:
            return version.revision
        return None

    @property
    def op(self):
        """Get the version operator of a package dependency.

        >>> from pkgcraft.dep import Operator, Dep
        >>> dep = Dep('cat/pkg')
        >>> dep.op is None
        True
        >>> dep = Dep('>=cat/pkg-1')
        >>> dep.op is Operator.GreaterOrEqual
        True
        >>> dep.op == '>='
        True
        """
        version = self.version
        if version is not None:
            return version.op
        return None

    @property
    def slot(self):
        """Get the slot of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2:3/4')
        >>> dep.slot
        '3'
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> dep.slot is None
        True
        """
        c_str = C.pkgcraft_dep_slot(self.ptr)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def subslot(self):
        """Get the subslot of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2:3/4')
        >>> dep.subslot
        '4'
        >>> dep = Dep('=cat/pkg-1-r2:3')
        >>> dep.subslot is None
        True
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> dep.subslot is None
        True
        """
        c_str = C.pkgcraft_dep_subslot(self.ptr)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def slot_op(self):
        """Get the slot operator of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> dep.slot_op is None
        True
        >>> dep = Dep('=cat/pkg-1-r2:=')
        >>> dep.slot_op is SlotOperator.Equal
        True
        >>> dep = Dep('=cat/pkg-1-r2:0=')
        >>> dep.slot_op is SlotOperator.Equal
        True
        >>> dep = Dep('=cat/pkg-1-r2:*')
        >>> dep.slot_op is SlotOperator.Star
        True
        """
        cdef int slot_op = C.pkgcraft_dep_slot_op(self.ptr)
        if slot_op > 0:
            return SlotOperator(slot_op)
        return None

    @property
    def use(self):
        """Get the USE dependencies of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2[a,b,c]')
        >>> dep.use
        ('a', 'b', 'c')
        >>> dep = Dep('=cat/pkg-1-r2[-a(-),b(+)=,!c(-)?]')
        >>> dep.use
        ('-a(-)', 'b(+)=', '!c(-)?')
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> dep.use is None
        True
        """
        cdef char **use
        cdef size_t length

        if self._use is SENTINEL:
            use = C.pkgcraft_dep_use_deps(self.ptr, &length)
            if use is not NULL:
                self._use = tuple(use[i].decode() for i in range(length))
                C.pkgcraft_str_array_free(use, length)
            else:
                self._use = None
        return self._use

    @property
    def repo(self):
        """Get the repo of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2::repo')
        >>> dep.repo
        'repo'
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> dep.repo is None
        True
        """
        c_str = C.pkgcraft_dep_repo(self.ptr)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def p(self):
        """Get the package and revision of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> dep.p
        'pkg-1'
        >>> dep = Dep('cat/pkg')
        >>> dep.p
        'pkg'
        """
        c_str = C.pkgcraft_dep_p(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    @property
    def pf(self):
        """Get the package, version, and revision of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> dep.pf
        'pkg-1-r2'
        >>> dep = Dep('=cat/pkg-1-r0')
        >>> dep.pf
        'pkg-1-r0'
        >>> dep = Dep('cat/pkg')
        >>> dep.pf
        'pkg'
        """
        c_str = C.pkgcraft_dep_pf(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    @property
    def pr(self):
        """Get the revision of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> dep.pr
        'r2'
        >>> dep = Dep('=cat/pkg-1-r0')
        >>> dep.pr
        'r0'
        >>> dep = Dep('cat/pkg')
        >>> dep.pr is None
        True
        """
        c_str = C.pkgcraft_dep_pr(self.ptr)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def pv(self):
        """Get the version of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> dep.pv
        '1'
        >>> dep = Dep('=cat/pkg-1-r0')
        >>> dep.pv
        '1'
        >>> dep = Dep('cat/pkg')
        >>> dep.pv is None
        True
        """
        c_str = C.pkgcraft_dep_pv(self.ptr)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def pvr(self):
        """Get the version and revision of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> dep.pvr
        '1-r2'
        >>> dep = Dep('=cat/pkg-1-r0')
        >>> dep.pvr
        '1-r0'
        >>> dep = Dep('cat/pkg')
        >>> dep.pvr is None
        True
        """
        c_str = C.pkgcraft_dep_pvr(self.ptr)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def cpn(self):
        """Get the category and package of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> dep.cpn
        'cat/pkg'
        >>> dep = Dep('cat/pkg')
        >>> dep.cpn
        'cat/pkg'
        """
        c_str = C.pkgcraft_dep_cpn(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    @property
    def cpv(self):
        """Get the category, package, and version of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2:3/4[u1,!u2?]')
        >>> dep.cpv
        'cat/pkg-1-r2'
        >>> dep = Dep('cat/pkg')
        >>> dep.cpv
        'cat/pkg'
        """
        c_str = C.pkgcraft_dep_cpv(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def matches(self, Restrict r not None):
        """Determine if a restriction matches a package dependency."""
        return C.pkgcraft_dep_restrict_matches(self.ptr, r.ptr)

    def intersects(self, other):
        """Determine intersection between two Cpv or Dep objects.

        >>> from pkgcraft.dep import Cpv, Dep
        >>> cpv = Cpv('cat/pkg-2-r1')
        >>> dep = Dep('>cat/pkg-1')
        >>> cpv.intersects(dep) and dep.intersects(cpv)
        True
        """
        if isinstance(other, Dep):
            return C.pkgcraft_dep_intersects(self.ptr, (<Dep>other).ptr)
        if isinstance(other, Cpv):
            return C.pkgcraft_dep_intersects_cpv(self.ptr, (<Cpv>other).ptr)
        else:
            raise TypeError(f"{other.__class__.__name__!r} unsupported type")

    def __lt__(self, other):
        if isinstance(other, Dep):
            return C.pkgcraft_dep_cmp(self.ptr, (<Dep>other).ptr) == -1
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, Dep):
            return C.pkgcraft_dep_cmp(self.ptr, (<Dep>other).ptr) <= 0
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, Dep):
            return C.pkgcraft_dep_cmp(self.ptr, (<Dep>other).ptr) == 0
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, Dep):
            return C.pkgcraft_dep_cmp(self.ptr, (<Dep>other).ptr) != 0
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, Dep):
            return C.pkgcraft_dep_cmp(self.ptr, (<Dep>other).ptr) >= 0
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, Dep):
            return C.pkgcraft_dep_cmp(self.ptr, (<Dep>other).ptr) == 1
        return NotImplemented

    def __str__(self):
        c_str = C.pkgcraft_dep_str(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        if not self._hash:
            self._hash = C.pkgcraft_dep_hash(self.ptr)
        return self._hash

    def __reduce__(self):
        """Support pickling Dep objects."""
        return self.__class__, (str(self), self.eapi)

    def __dealloc__(self):
        C.pkgcraft_dep_free(self.ptr)