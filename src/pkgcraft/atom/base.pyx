import functools
from enum import Enum

cimport cython

from .. cimport pkgcraft_c as C
from .._misc cimport SENTINEL
from ..eapi cimport Eapi
from ..restrict cimport Restrict
from .version cimport Version

from ..eapi import EAPIS
from ..error import InvalidAtom, InvalidCpv


cdef class Cpv:
    """CPV string parsing.

    >>> from pkgcraft.atom import Cpv

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
    cdef Cpv from_ptr(const C.Atom *ptr):
        """Create instance from a borrowed pointer."""
        obj = <Cpv>Cpv.__new__(Cpv)
        obj.ptr = <C.Atom *>ptr
        obj.ref = True
        return obj

    @property
    def category(self):
        """Get an atom's category.

        >>> from pkgcraft.atom import Cpv
        >>> a = Cpv('cat/pkg-1-r2')
        >>> a.category
        'cat'
        """
        if self._category is None:
            c_str = C.pkgcraft_atom_category(self.ptr)
            self._category = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._category

    @property
    def package(self):
        """Get an atom's package.

        >>> from pkgcraft.atom import Cpv
        >>> a = Cpv('cat/pkg-1-r2')
        >>> a.package
        'pkg'
        """
        if self._package is None:
            c_str = C.pkgcraft_atom_package(self.ptr)
            self._package = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._package

    @property
    def version(self):
        """Get an atom's version.

        >>> from pkgcraft.atom import Cpv
        >>> a = Cpv('cat/pkg-1-r2')
        >>> str(a.version)
        '1-r2'
        """
        if self._version is SENTINEL:
            ptr = C.pkgcraft_atom_version(self.ptr)
            self._version = Version.from_ptr(ptr) if ptr is not NULL else None
        return self._version

    @property
    def revision(self):
        """Get an atom's revision.

        >>> from pkgcraft.atom import Cpv
        >>> a = Cpv('cat/pkg-1-r2')
        >>> a.revision
        '2'
        >>> a = Cpv('cat/pkg-1')
        >>> a.revision
        '0'
        """
        c_str = C.pkgcraft_atom_revision(self.ptr)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def cpn(self):
        """Get the concatenated string of an atom's category and package.

        >>> from pkgcraft.atom import Cpv
        >>> a = Cpv('cat/pkg-1-r2')
        >>> a.cpn
        'cat/pkg'
        """
        c_str = C.pkgcraft_atom_cpn(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def matches(self, Restrict r):
        """Determine if a restriction matches an atom."""
        return C.pkgcraft_atom_restrict_matches(self.ptr, r.ptr)

    def __lt__(self, Cpv other):
        return C.pkgcraft_atom_cmp(self.ptr, other.ptr) == -1

    def __le__(self, Cpv other):
        return C.pkgcraft_atom_cmp(self.ptr, other.ptr) <= 0

    def __eq__(self, Cpv other):
        return C.pkgcraft_atom_cmp(self.ptr, other.ptr) == 0

    def __ne__(self, Cpv other):
        return C.pkgcraft_atom_cmp(self.ptr, other.ptr) != 0

    def __gt__(self, Cpv other):
        return C.pkgcraft_atom_cmp(self.ptr, other.ptr) == 1

    def __ge__(self, Cpv other):
        return C.pkgcraft_atom_cmp(self.ptr, other.ptr) >= 0

    def __str__(self):
        c_str = C.pkgcraft_atom_str(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        if not self._hash:
            self._hash = C.pkgcraft_atom_hash(self.ptr)
        return self._hash

    def __reduce__(self):
        """Support pickling Cpv objects."""
        c_str = C.pkgcraft_atom_str(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return (self.__class__, (s,))

    # TODO: move to __del__() when migrating to >=cython-3 since it's not
    # supported in <cython-3 for cdef classes:
    # https://github.com/cython/cython/pull/3804
    def __dealloc__(self):
        if not self.ref:
            C.pkgcraft_atom_free(self.ptr)


# TODO: merge with Atom.cached function when cython bug is fixed
# https://github.com/cython/cython/issues/1434
@functools.lru_cache(maxsize=10000)
def _cached_atom(cls, atom, eapi=None):
    return cls(atom, eapi)


class Blocker(Enum):
    Strong = 0
    Weak = 1

    @staticmethod
    def from_str(str s not None):
        blocker = C.pkgcraft_atom_blocker_from_str(s.encode())
        if blocker >= 0:
            return Blocker(blocker)
        raise ValueError(f'invalid blocker: {s}')


class SlotOperator(Enum):
    Equal = 0
    Star = 1

    @staticmethod
    def from_str(str s not None):
        slot_op = C.pkgcraft_atom_slot_op_from_str(s.encode())
        if slot_op >= 0:
            return SlotOperator(slot_op)
        raise ValueError(f'invalid slot operator: {s}')


@cython.final
cdef class Atom(Cpv):
    """Package atom parsing.

    >>> from pkgcraft.atom import Atom

    Simple atom
    >>> a = Atom('cat/pkg')
    >>> a.category
    'cat'
    >>> a.package
    'pkg'

    Complex atom
    >>> a = Atom('=cat/pkg-1-r2:0/2[a,b]::repo')
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

    Invalid atom
    >>> Atom('cat/pkg-1')
    Traceback (most recent call last):
        ...
    pkgcraft.error.InvalidAtom: parsing failure: invalid atom: cat/pkg-1
    ...
    """
    def __cinit__(self):
        self._use = SENTINEL

    def __init__(self, str s not None, eapi=None):
        cdef const C.Eapi *eapi_ptr = NULL
        if isinstance(eapi, Eapi):
            eapi_ptr = (<Eapi>eapi).ptr
        elif eapi is not None:
            eapi_ptr = (<Eapi>EAPIS.get(eapi)).ptr

        self.ptr = C.pkgcraft_atom_new(s.encode(), eapi_ptr)

        if self.ptr is NULL:
            raise InvalidAtom

    @staticmethod
    cdef Atom from_ptr(const C.Atom *ptr):
        """Create instance from a borrowed pointer."""
        obj = <Atom>Atom.__new__(Atom)
        obj.ptr = <C.Atom *>ptr
        obj.ref = True
        return obj

    @classmethod
    def cached(cls, s, eapi=None):
        """Return a cached Atom if one exists, otherwise return a new instance."""
        return _cached_atom(cls, s, eapi)

    @property
    def blocker(self):
        """Get an atom's blocker.

        >>> from pkgcraft.atom import Atom
        >>> a = Atom('cat/pkg')
        >>> a.blocker is None
        True
        >>> a = Atom('!cat/pkg')
        >>> a.blocker is Blocker.Weak
        True
        >>> a = Atom('!!cat/pkg')
        >>> a.blocker is Blocker.Strong
        True
        """
        cdef int blocker = C.pkgcraft_atom_blocker(self.ptr)
        if blocker >= 0:
            return Blocker(blocker)
        return None

    @property
    def slot(self):
        """Get an atom's slot.

        >>> from pkgcraft.atom import Atom
        >>> a = Atom('=cat/pkg-1-r2:3/4')
        >>> a.slot
        '3'
        >>> a = Atom('=cat/pkg-1-r2')
        >>> a.slot is None
        True
        """
        c_str = C.pkgcraft_atom_slot(self.ptr)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def subslot(self):
        """Get an atom's subslot.

        >>> from pkgcraft.atom import Atom
        >>> a = Atom('=cat/pkg-1-r2:3/4')
        >>> a.subslot
        '4'
        >>> a = Atom('=cat/pkg-1-r2:3')
        >>> a.subslot is None
        True
        >>> a = Atom('=cat/pkg-1-r2')
        >>> a.subslot is None
        True
        """
        c_str = C.pkgcraft_atom_subslot(self.ptr)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def slot_op(self):
        """Get an atom's slot operator.

        >>> from pkgcraft.atom import Atom
        >>> a = Atom('=cat/pkg-1-r2')
        >>> a.slot_op is None
        True
        >>> a = Atom('=cat/pkg-1-r2:=')
        >>> a.slot_op is SlotOperator.Equal
        True
        >>> a = Atom('=cat/pkg-1-r2:0=')
        >>> a.slot_op is SlotOperator.Equal
        True
        >>> a = Atom('=cat/pkg-1-r2:*')
        >>> a.slot_op is SlotOperator.Star
        True
        """
        cdef int slot_op = C.pkgcraft_atom_slot_op(self.ptr)
        if slot_op >= 0:
            return SlotOperator(slot_op)
        return None

    @property
    def use(self):
        """Get an atom's USE deps.

        >>> from pkgcraft.atom import Atom
        >>> a = Atom('=cat/pkg-1-r2[a,b,c]')
        >>> a.use
        ('a', 'b', 'c')
        >>> a = Atom('=cat/pkg-1-r2[-a(-),b(+)=,!c(-)?]')
        >>> a.use
        ('-a(-)', 'b(+)=', '!c(-)?')
        >>> a = Atom('=cat/pkg-1-r2')
        >>> a.use is None
        True
        """
        cdef char **use
        cdef size_t length

        if self._use is SENTINEL:
            use = C.pkgcraft_atom_use_deps(self.ptr, &length)
            if use is not NULL:
                self._use = tuple(use[i].decode() for i in range(length))
                C.pkgcraft_str_array_free(use, length)
            else:
                self._use = None
        return self._use

    @property
    def repo(self):
        """Get an atom's repo.

        >>> from pkgcraft.atom import Atom
        >>> a = Atom('=cat/pkg-1-r2::repo')
        >>> a.repo
        'repo'
        >>> a = Atom('=cat/pkg-1-r2')
        >>> a.repo is None
        True
        """
        c_str = C.pkgcraft_atom_repo(self.ptr)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def cpv(self):
        """Get the concatenated string of an atom's category, package, and version.

        >>> from pkgcraft.atom import Atom
        >>> a = Atom('=cat/pkg-1-r2:3/4[u1,!u2?]')
        >>> a.cpv
        'cat/pkg-1-r2'
        """
        c_str = C.pkgcraft_atom_cpv(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s
