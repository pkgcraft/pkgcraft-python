import functools
from enum import IntEnum

cimport cython

from .. cimport pkgcraft_c as C
from .._misc cimport SENTINEL
from ..eapi cimport eapi_from_obj
from ..restrict cimport Restrict
from .version cimport Version

from ..error import InvalidCpv, InvalidDep


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
    def __cinit__(self):
        self._version = SENTINEL

    def __init__(self, str s not None):
        self.ptr = C.pkgcraft_cpv_new(s.encode())
        if self.ptr is NULL:
            raise InvalidCpv

    @staticmethod
    cdef Cpv from_ptr(C.Dep *ptr):
        """Create a Cpv from a pointer."""
        obj = <Cpv>Cpv.__new__(Cpv)
        obj.ptr = <C.Dep *>ptr
        return obj

    @property
    def category(self):
        """Get the category of a package dependency.

        >>> from pkgcraft.dep import Cpv
        >>> a = Cpv('cat/pkg-1-r2')
        >>> a.category
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

        >>> from pkgcraft.dep import Cpv
        >>> a = Cpv('cat/pkg-1-r2')
        >>> a.package
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

        >>> from pkgcraft.dep import Cpv, Dep
        >>> a = Cpv('cat/pkg-1-r2')
        >>> str(a.version)
        '1-r2'
        >>> a = Dep('cat/pkg')
        >>> a.version is None
        True
        """
        if self._version is SENTINEL:
            ptr = C.pkgcraft_dep_version(self.ptr)
            self._version = Version.from_ptr(ptr)
        return self._version

    @property
    def revision(self):
        """Get the revision of a package dependency.

        >>> from pkgcraft.dep import Cpv, Dep
        >>> a = Cpv('cat/pkg-1-r2')
        >>> a.revision
        '2'
        >>> a = Cpv('cat/pkg-1-r0')
        >>> a.revision
        '0'
        >>> a = Cpv('cat/pkg-1')
        >>> a.revision is None
        True
        >>> a = Dep('cat/pkg')
        >>> a.revision is None
        True
        """
        version = self.version
        if version is not None:
            return version.revision
        return None

    @property
    def p(self):
        """Get the package and revision of a package dependency.

        >>> from pkgcraft.dep import Cpv, Dep
        >>> a = Cpv('cat/pkg-1-r2')
        >>> a.p
        'pkg-1'
        >>> a = Dep('cat/pkg')
        >>> a.p
        'pkg'
        """
        c_str = C.pkgcraft_dep_p(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    @property
    def pf(self):
        """Get the package, version, and revision of a package dependency.

        >>> from pkgcraft.dep import Cpv, Dep
        >>> a = Cpv('cat/pkg-1-r2')
        >>> a.pf
        'pkg-1-r2'
        >>> a = Cpv('cat/pkg-1-r0')
        >>> a.pf
        'pkg-1-r0'
        >>> a = Cpv('cat/pkg-1')
        >>> a.pf
        'pkg-1'
        >>> a = Dep('cat/pkg')
        >>> a.pf
        'pkg'
        """
        c_str = C.pkgcraft_dep_pf(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    @property
    def pr(self):
        """Get the revision of a package dependency.

        >>> from pkgcraft.dep import Cpv, Dep
        >>> a = Cpv('cat/pkg-1-r2')
        >>> a.pr
        'r2'
        >>> a = Cpv('cat/pkg-1-r0')
        >>> a.pr
        'r0'
        >>> a = Cpv('cat/pkg-1')
        >>> a.pr
        'r0'
        >>> a = Dep('cat/pkg')
        >>> a.pr is None
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

        >>> from pkgcraft.dep import Cpv, Dep
        >>> a = Cpv('cat/pkg-1-r2')
        >>> a.pv
        '1'
        >>> a = Cpv('cat/pkg-1-r0')
        >>> a.pv
        '1'
        >>> a = Cpv('cat/pkg-1')
        >>> a.pv
        '1'
        >>> a = Dep('cat/pkg')
        >>> a.pv is None
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

        >>> from pkgcraft.dep import Cpv, Dep
        >>> a = Cpv('cat/pkg-1-r2')
        >>> a.pvr
        '1-r2'
        >>> a = Cpv('cat/pkg-1-r0')
        >>> a.pvr
        '1-r0'
        >>> a = Cpv('cat/pkg-1')
        >>> a.pvr
        '1'
        >>> a = Dep('cat/pkg')
        >>> a.pvr is None
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

        >>> from pkgcraft.dep import Cpv, Dep
        >>> a = Cpv('cat/pkg-1-r2')
        >>> a.cpn
        'cat/pkg'
        >>> a = Dep('cat/pkg')
        >>> a.cpn
        'cat/pkg'
        """
        c_str = C.pkgcraft_dep_cpn(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    @property
    def cpv(self):
        """Get the category, package, and version of a package dependency.

        >>> from pkgcraft.dep import Cpv, Dep
        >>> a = Cpv('cat/pkg-1-r2')
        >>> a.cpv
        'cat/pkg-1-r2'
        >>> a = Dep('=cat/pkg-1-r2:3/4[u1,!u2?]')
        >>> a.cpv
        'cat/pkg-1-r2'
        >>> a = Dep('cat/pkg')
        >>> a.cpv
        'cat/pkg'
        """
        c_str = C.pkgcraft_dep_cpv(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def matches(self, Restrict r not None):
        """Determine if a restriction matches a package dependency."""
        return C.pkgcraft_dep_restrict_matches(self.ptr, r.ptr)

    def intersects(self, Cpv other not None):
        """Determine if two package dependencies intersect.

        >>> from pkgcraft.dep import Cpv, Dep
        >>> dep = Dep('>cat/pkg-1')
        >>> cpv = Cpv('cat/pkg-2-r1')
        >>> dep.intersects(cpv) and cpv.intersects(dep)
        True
        >>> d1 = Dep('>cat/pkg-1-r1')
        >>> d2 = Dep('=cat/pkg-1-r1')
        >>> d1.intersects(d2) or d2.intersects(d1)
        False
        """
        return C.pkgcraft_dep_intersects(self.ptr, other.ptr)

    def __lt__(self, other):
        if isinstance(other, Cpv):
            return C.pkgcraft_dep_cmp(self.ptr, (<Cpv>other).ptr) == -1
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, Cpv):
            return C.pkgcraft_dep_cmp(self.ptr, (<Cpv>other).ptr) <= 0
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, Cpv):
            return C.pkgcraft_dep_cmp(self.ptr, (<Cpv>other).ptr) == 0
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, Cpv):
            return C.pkgcraft_dep_cmp(self.ptr, (<Cpv>other).ptr) != 0
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, Cpv):
            return C.pkgcraft_dep_cmp(self.ptr, (<Cpv>other).ptr) >= 0
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, Cpv):
            return C.pkgcraft_dep_cmp(self.ptr, (<Cpv>other).ptr) == 1
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
        """Support pickling Cpv objects."""
        return self.__class__, (str(self),)

    def __dealloc__(self):
        C.pkgcraft_dep_free(self.ptr)


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
cdef class Dep(Cpv):
    """Package dependency parsing.

    >>> from pkgcraft.dep import Dep

    Unversioned package dependency
    >>> a = Dep('cat/pkg')
    >>> a.category
    'cat'
    >>> a.package
    'pkg'

    Complex package dependency
    >>> a = Dep('=cat/pkg-1-r2:0/2[a,b]::repo')
    >>> a.category
    'cat'
    >>> a.package
    'pkg'
    >>> str(a.version)
    '1-r2'
    >>> a.revision
    '2'
    >>> a.slot
    '0'
    >>> a.subslot
    '2'
    >>> a.use
    ('a', 'b')
    >>> a.repo
    'repo'

    Invalid package dependency
    >>> Dep('cat/pkg-1')
    Traceback (most recent call last):
        ...
    pkgcraft.error.InvalidDep: parsing failure: invalid dep: cat/pkg-1
    ...
    """
    def __cinit__(self):
        self._use = SENTINEL

    def __init__(self, str s not None, eapi=None):
        cdef const C.Eapi *eapi_ptr = NULL
        if eapi is not None:
            eapi_ptr = eapi_from_obj(eapi).ptr

        self.ptr = C.pkgcraft_dep_new(s.encode(), eapi_ptr)
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
        >>> a = Dep('cat/pkg')
        >>> a.blocker is None
        True
        >>> a = Dep('!cat/pkg')
        >>> a.blocker is Blocker.Weak
        True
        >>> a = Dep('!!cat/pkg')
        >>> a.blocker is Blocker.Strong
        True
        """
        cdef int blocker = C.pkgcraft_dep_blocker(self.ptr)
        if blocker > 0:
            return Blocker(blocker)
        return None

    @property
    def op(self):
        """Get the version operator of a package dependency.

        >>> from pkgcraft.dep import Operator, Dep
        >>> a = Dep('cat/pkg')
        >>> a.op is None
        True
        >>> a = Dep('>=cat/pkg-1')
        >>> a.op is Operator.GreaterOrEqual
        True
        >>> a.op == '>='
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
        >>> a = Dep('=cat/pkg-1-r2:3/4')
        >>> a.slot
        '3'
        >>> a = Dep('=cat/pkg-1-r2')
        >>> a.slot is None
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
        >>> a = Dep('=cat/pkg-1-r2:3/4')
        >>> a.subslot
        '4'
        >>> a = Dep('=cat/pkg-1-r2:3')
        >>> a.subslot is None
        True
        >>> a = Dep('=cat/pkg-1-r2')
        >>> a.subslot is None
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
        >>> a = Dep('=cat/pkg-1-r2')
        >>> a.slot_op is None
        True
        >>> a = Dep('=cat/pkg-1-r2:=')
        >>> a.slot_op is SlotOperator.Equal
        True
        >>> a = Dep('=cat/pkg-1-r2:0=')
        >>> a.slot_op is SlotOperator.Equal
        True
        >>> a = Dep('=cat/pkg-1-r2:*')
        >>> a.slot_op is SlotOperator.Star
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
        >>> a = Dep('=cat/pkg-1-r2[a,b,c]')
        >>> a.use
        ('a', 'b', 'c')
        >>> a = Dep('=cat/pkg-1-r2[-a(-),b(+)=,!c(-)?]')
        >>> a.use
        ('-a(-)', 'b(+)=', '!c(-)?')
        >>> a = Dep('=cat/pkg-1-r2')
        >>> a.use is None
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
        >>> a = Dep('=cat/pkg-1-r2::repo')
        >>> a.repo
        'repo'
        >>> a = Dep('=cat/pkg-1-r2')
        >>> a.repo is None
        True
        """
        c_str = C.pkgcraft_dep_repo(self.ptr)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None
