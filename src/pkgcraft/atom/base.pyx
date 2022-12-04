import functools
from enum import Enum

cimport cython

from .. cimport pkgcraft_c as C
from .._misc cimport SENTINEL
from .cpv cimport Cpv
from ..eapi cimport Eapi
from ..eapi import EAPIS
from ..error import InvalidAtom


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
        cdef const C.Eapi *eapi_p = NULL
        if isinstance(eapi, Eapi):
            eapi_p = (<Eapi>eapi)._eapi
        elif eapi is not None:
            eapi_p = (<Eapi>EAPIS.get(eapi))._eapi

        self._atom = C.pkgcraft_atom_new(s.encode(), eapi_p)

        if self._atom is NULL:
            raise InvalidAtom

    @staticmethod
    cdef Atom from_ptr(const C.Atom *atom):
        """Create instance from a borrowed pointer."""
        obj = <Atom>Atom.__new__(Atom)
        obj._atom = <C.Atom *>atom
        obj._ref = True
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
        cdef int blocker = C.pkgcraft_atom_blocker(self._atom)
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
        c_str = C.pkgcraft_atom_slot(self._atom)
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
        c_str = C.pkgcraft_atom_subslot(self._atom)
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
        cdef int slot_op = C.pkgcraft_atom_slot_op(self._atom)
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
            use = C.pkgcraft_atom_use_deps(self._atom, &length)
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
        c_str = C.pkgcraft_atom_repo(self._atom)
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
        c_str = C.pkgcraft_atom_cpv(self._atom)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s
