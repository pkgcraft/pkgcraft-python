from enum import IntEnum
from types import MappingProxyType

cimport cython
from cpython.mem cimport PyMem_Free, PyMem_Malloc

from .. cimport C
from .._misc cimport SENTINEL, cstring_iter, cstring_to_str
from ..eapi cimport Eapi
from ..restrict cimport Restrict
from ..types cimport OrderedFrozenSet
from . cimport Cpv
from .version cimport Version

from .._misc import LruInstanceCache
from ..eapi import EAPI_LATEST
from ..error import InvalidDep


class Blocker(IntEnum):
    """Package dependency blocker."""
    Strong = C.BLOCKER_STRONG
    Weak = C.BLOCKER_WEAK

    @staticmethod
    def from_str(s: str):
        if blocker := C.pkgcraft_dep_blocker_from_str(s.encode()):
            return Blocker(blocker)
        raise ValueError(f'invalid blocker: {s}')

    def __str__(self):
        return cstring_to_str(C.pkgcraft_dep_blocker_str(self))

    def __eq__(self, other):
        if isinstance(other, str):
            return str(self) == other
        return int(self) == other


class SlotOperator(IntEnum):
    """Package dependency slot operator."""
    Equal = C.SLOT_OPERATOR_EQUAL
    Star = C.SLOT_OPERATOR_STAR

    @staticmethod
    def from_str(s: str):
        if slot_op := C.pkgcraft_dep_slot_op_from_str(s.encode()):
            return SlotOperator(slot_op)
        raise ValueError(f'invalid slot operator: {s}')

    def __str__(self):
        return cstring_to_str(C.pkgcraft_dep_slot_op_str(self))

    def __eq__(self, other):
        if isinstance(other, str):
            return str(self) == other
        return int(self) == other


# mapping of field names to values for Dep.without()
_DEP_FIELDS = MappingProxyType({
    'category': C.DEP_FIELD_CATEGORY,
    'package': C.DEP_FIELD_PACKAGE,
    'blocker': C.DEP_FIELD_BLOCKER,
    'version': C.DEP_FIELD_VERSION,
    'slot': C.DEP_FIELD_SLOT,
    'subslot': C.DEP_FIELD_SUBSLOT,
    'slot_op': C.DEP_FIELD_SLOT_OP,
    'use_deps': C.DEP_FIELD_USE_DEPS,
    'repo': C.DEP_FIELD_REPO,
})

cdef class Dep:
    """Package dependency.

    >>> from pkgcraft.dep import Dep
    >>> dep = Dep('=cat/pkg-1-r2:0/2::repo[a,b]')
    >>> dep.category
    'cat'
    >>> dep.package
    'pkg'
    >>> str(dep.version)
    '=1-r2'
    >>> str(dep.revision)
    '2'
    >>> dep.slot
    '0'
    >>> dep.subslot
    '2'
    >>> list(dep.use_deps)
    ['a', 'b']
    >>> dep.repo
    'repo'

    Invalid package dependency
    >>> Dep('cat/pkg-1')
    Traceback (most recent call last):
        ...
    pkgcraft.error.InvalidDep: parsing failure: invalid dep: cat/pkg-1
    """
    def __cinit__(self):
        self._blocker = SENTINEL
        self._version = SENTINEL
        self._slot_op = SENTINEL
        self._use_deps = SENTINEL
        self.eapi = EAPI_LATEST

    def __init__(self, s: str, /, eapi=None):
        if eapi is not None:
            self.eapi = Eapi._from_obj(eapi)

        self.ptr = C.pkgcraft_dep_new(s.encode(), self.eapi.ptr)
        if self.ptr is NULL:
            raise InvalidDep

    @staticmethod
    cdef Dep from_ptr(C.Dep *ptr):
        """Create a Dep from a pointer."""
        inst = <Dep>Dep.__new__(Dep)
        inst.ptr = <C.Dep *>ptr
        return inst

    @staticmethod
    def valid(s: str, eapi=None, raised=False):
        """Determine if a string is a valid package dependency.

        >>> from pkgcraft.dep import Dep
        >>> Dep.valid('=cat/pkg-1')
        True
        """
        cdef const C.Eapi *eapi_ptr = NULL
        if eapi is not None:
            eapi_ptr = Eapi._from_obj(eapi).ptr

        valid = C.pkgcraft_dep_valid(s.encode(), eapi_ptr) is not NULL
        if not valid and raised:
            raise InvalidDep
        return valid

    def without(self, *fields):
        """Return a Dep without the given attributes.

        The field arguments must be attribute names including the following:
        blocker, version, slot, subslot, slot_op, use_deps, and repo.

        >>> d = Dep('>=cat/pkg-1.2-r3:4/5[a,b]')
        >>> str(d.without("use_deps"))
        '>=cat/pkg-1.2-r3:4/5'
        >>> str(d.without("version"))
        'cat/pkg:4/5[a,b]'
        >>> str(d.without("use_deps", "version"))
        'cat/pkg:4/5'
        >>> str(d.without("use_deps", "version", "subslot"))
        'cat/pkg:4'
        >>> str(d.without("use_deps", "version", "slot"))
        'cat/pkg'
        """
        cdef int field

        if fields:
            dep_fields = <C.DepField *>PyMem_Malloc(len(fields) * sizeof(C.DepField))
            if not fields:  # pragma: no cover
                raise MemoryError

            for (i, name) in enumerate(fields):
                if field := _DEP_FIELDS.get(name, 0):
                    dep_fields[i] = field
                else:
                    raise ValueError(f'invalid field: {name}')

            ptr = C.pkgcraft_dep_without(self.ptr, dep_fields, len(fields))
            PyMem_Free(dep_fields)

            if ptr is NULL:
                raise InvalidDep
            elif ptr != self.ptr:
                return Dep.from_ptr(ptr)

        return self

    def modify(self, **kwargs):
        """Return a Dep modifying the given attributes.

        The keyword arguments must be attribute names with their corresponding
        string values or None for removal. Supported attribute names include
        the following: blocker, version, slot, subslot, slot_op, use_deps, and
        repo.

        Adding attributes
        >>> from pkgcraft.dep import Dep
        >>> d = Dep('cat/pkg')
        >>> str(d.modify(version='>=1.2.3-r4'))
        '>=cat/pkg-1.2.3-r4'
        >>> str(d.modify(repo='repo'))
        'cat/pkg::repo'
        >>> str(d.modify(version='~0.1', slot='2/3=', use_deps='a,b,c', repo='test'))
        '~cat/pkg-0.1:2/3=::test[a,b,c]'

        Adding and removing attributes
        >>> d = Dep('>=cat/pkg-1.2-r3:4/5[a,b]')
        >>> str(d.modify(use_deps=None, repo='test'))
        '>=cat/pkg-1.2-r3:4/5::test'
        >>> str(d.modify(slot='3/4=', version=None))
        'cat/pkg:3/4=[a,b]'
        """
        cdef int field

        if kwargs:
            fields = <C.DepField *>PyMem_Malloc(len(kwargs) * sizeof(C.DepField))
            if not fields:  # pragma: no cover
                raise MemoryError
            values_encoded = [s.encode() if isinstance(s, str) else None for s in kwargs.values()]
            values = <char **>PyMem_Malloc(len(kwargs) * sizeof(char *))
            if not values:  # pragma: no cover
                raise MemoryError

            for (i, (name, val)) in enumerate(kwargs.items()):
                if field := _DEP_FIELDS.get(name, 0):
                    fields[i] = field
                    value = values_encoded[i]
                    if value is None:
                        values[i] = NULL
                    else:
                        values[i] = value
                else:
                    raise ValueError(f'invalid field: {name}')

            ptr = C.pkgcraft_dep_modify(self.ptr, fields, values, len(kwargs))
            PyMem_Free(fields)
            PyMem_Free(values)

            if ptr is NULL:
                raise InvalidDep
            elif ptr != self.ptr:
                return Dep.from_ptr(ptr)

        return self

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
        >>> dep.blocker == '!!'
        True
        """
        if self._blocker is SENTINEL:
            if blocker := C.pkgcraft_dep_blocker(self.ptr):
                self._blocker = Blocker(blocker)
            else:
                self._blocker = None
        return self._blocker

    @property
    def category(self):
        """Get the category of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> dep.category
        'cat'
        """
        if self._category is None:
            self._category = cstring_to_str(C.pkgcraft_dep_category(self.ptr))
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
            self._package = cstring_to_str(C.pkgcraft_dep_package(self.ptr))
        return self._package

    @property
    def version(self):
        """Get the version of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> str(dep.version)
        '=1-r2'
        >>> dep = Dep('cat/pkg')
        >>> dep.version is None
        True
        """
        if self._version is SENTINEL:
            ptr = C.pkgcraft_dep_version(self.ptr)
            self._version = Version.from_ptr(ptr) if ptr is not NULL else None
        return self._version

    @property
    def revision(self):
        """Get the revision of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> str(dep.revision)
        '2'
        >>> dep = Dep('=cat/pkg-1-r0')
        >>> str(dep.revision)
        '0'
        >>> dep = Dep('cat/pkg')
        >>> dep.revision is None
        True
        """
        cdef Version version = self.version
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
        cdef Version version = self.version
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
        if self._slot is None:
            self._slot = cstring_to_str(C.pkgcraft_dep_slot(self.ptr))
        return self._slot

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
        if self._subslot is None:
            self._subslot = cstring_to_str(C.pkgcraft_dep_subslot(self.ptr))
        return self._subslot

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
        if self._slot_op is SENTINEL:
            if slot_op := C.pkgcraft_dep_slot_op(self.ptr):
                self._slot_op = SlotOperator(slot_op)
            else:
                self._slot_op = None
        return self._slot_op

    @property
    def use_deps(self):
        """Get the USE dependencies of a package dependency.

        >>> from pkgcraft.dep import Dep
        >>> dep = Dep('=cat/pkg-1-r2[a,b,c]')
        >>> list(dep.use_deps)
        ['a', 'b', 'c']
        >>> dep = Dep('=cat/pkg-1-r2[-a(-),b(+)=,!c(-)?]')
        >>> list(dep.use_deps)
        ['-a(-)', 'b(+)=', '!c(-)?']
        >>> dep = Dep('=cat/pkg-1-r2')
        >>> dep.use_deps is None
        True
        """
        cdef size_t length
        if self._use_deps is SENTINEL:
            if c_strs := C.pkgcraft_dep_use_deps(self.ptr, &length):
                self._use_deps = OrderedFrozenSet(cstring_iter(c_strs, length))
            else:
                self._use_deps = None
        return self._use_deps

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
        if self._repo is None:
            self._repo = cstring_to_str(C.pkgcraft_dep_repo(self.ptr))
        return self._repo

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
        return cstring_to_str(C.pkgcraft_dep_p(self.ptr))

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
        return cstring_to_str(C.pkgcraft_dep_pf(self.ptr))

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
        return cstring_to_str(C.pkgcraft_dep_pr(self.ptr))

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
        return cstring_to_str(C.pkgcraft_dep_pv(self.ptr))

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
        return cstring_to_str(C.pkgcraft_dep_pvr(self.ptr))

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
        return cstring_to_str(C.pkgcraft_dep_cpn(self.ptr))

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
        return cstring_to_str(C.pkgcraft_dep_cpv(self.ptr))

    def matches(self, r: Restrict):
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
        elif isinstance(other, Cpv):
            return C.pkgcraft_dep_intersects_cpv(self.ptr, (<Cpv>other).ptr)
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
        return cstring_to_str(C.pkgcraft_dep_str(self.ptr))

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        if not self._hash:
            self._hash = C.pkgcraft_dep_hash(self.ptr)
        return self._hash

    def __reduce__(self):
        return self.__class__, (str(self), self.eapi)

    def __dealloc__(self):
        C.pkgcraft_dep_free(self.ptr)


class CachedDep(Dep, metaclass=LruInstanceCache):
    """Package dependency with LRU-based instance caching."""


@cython.final
cdef class Cpn(Dep):
    """Unversioned package dependency."""

    def __init__(self, s: str):
        self.ptr = C.pkgcraft_dep_new_cpn(s.encode())
        if self.ptr is NULL:
            raise InvalidDep

    def __reduce__(self):
        return self.__class__, (str(self),)
