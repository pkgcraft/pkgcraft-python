# SPDX-License-Identifier: MIT
# cython: language_level=3

import functools

from . cimport pkgcraft_c as C
from ._misc cimport SENTINEL
from .version cimport Version
from .error import PkgcraftError

include "pkgcraft.pxi"

# TODO: merge with Atom.cached function when cython bug is fixed
# https://github.com/cython/cython/issues/1434
@functools.lru_cache(maxsize=10000)
def _cached_atom(cls, atom_str, eapi_str=None):
    return cls(atom_str, eapi_str)


cdef class Cpv:
    """CPV string parsing.

    >>> from pkgcraft import Cpv

    Valid CPV
    >>> cpv = Cpv("cat/pkg-1-r2")
    >>> cpv.category
    'cat'
    >>> cpv.package
    'pkg'
    >>> str(cpv.version)
    '1-r2'

    Invalid CPV
    >>> cpv = Cpv("=cat/pkg-1-r2")
    Traceback (most recent call last):
        ...
    pkgcraft.error.PkgcraftError: parsing failure: invalid cpv: "=cat/pkg-1-r2"
      |
    1 | =cat/pkg-1-r2
      | ^ Expected: category name
      |
    """
    def __cinit__(self):
        self._version = SENTINEL

    def __init__(self, str atom_str):
        atom_bytes = atom_str.encode()
        cdef char* atom = atom_bytes

        self._atom = C.pkgcraft_cpv(atom)
        if not self._atom:
            raise PkgcraftError

    @property
    def category(self):
        """Get an atom's category.

        >>> from pkgcraft import Cpv
        >>> a = Cpv("cat/pkg-1-r2")
        >>> a.category
        'cat'
        """
        cdef char* c_str
        if self._category is None:
            c_str = C.pkgcraft_atom_category(self._atom)
            self._category = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._category

    @property
    def package(self):
        """Get an atom's package.

        >>> from pkgcraft import Cpv
        >>> a = Cpv("cat/pkg-1-r2")
        >>> a.package
        'pkg'
        """
        cdef char* c_str
        if self._package is None:
            c_str = C.pkgcraft_atom_package(self._atom)
            self._package = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._package

    @property
    def version(self):
        """Get an atom's version.

        >>> from pkgcraft import Cpv
        >>> a = Cpv("cat/pkg-1-r2")
        >>> str(a.version)
        '1-r2'
        """
        cdef const C.Version* ver

        if self._version is SENTINEL:
            ver = C.pkgcraft_atom_version(self._atom)
            self._version = Version.borrowed(ver) if ver else None
        return self._version

    @property
    def revision(self):
        """Get an atom's revision.

        >>> from pkgcraft import Cpv
        >>> a = Cpv("cat/pkg-1-r2")
        >>> a.revision
        '2'
        >>> a = Cpv("cat/pkg-1")
        >>> a.revision
        '0'
        """
        cdef char* c_str = C.pkgcraft_atom_revision(self._atom)
        if c_str:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def key(self):
        """Get the concatenated string of an atom's category and package.

        >>> from pkgcraft import Cpv
        >>> a = Cpv("cat/pkg-1-r2")
        >>> a.key
        'cat/pkg'
        """
        cdef char* c_str = C.pkgcraft_atom_key(self._atom)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __lt__(self, Cpv other):
        return C.pkgcraft_atom_cmp(self._atom, other._atom) == -1

    def __le__(self, Cpv other):
        return C.pkgcraft_atom_cmp(self._atom, other._atom) <= 0

    def __eq__(self, Cpv other):
        return C.pkgcraft_atom_cmp(self._atom, other._atom) == 0

    def __ne__(self, Cpv other):
        return C.pkgcraft_atom_cmp(self._atom, other._atom) != 0

    def __gt__(self, Cpv other):
        return C.pkgcraft_atom_cmp(self._atom, other._atom) == 1

    def __ge__(self, Cpv other):
        return C.pkgcraft_atom_cmp(self._atom, other._atom) >= 0

    def __str__(self):
        cdef char* c_str = C.pkgcraft_atom_str(self._atom)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __repr__(self):
        cdef size_t addr = <size_t>&self._atom
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        return C.pkgcraft_atom_hash(self._atom)

    def __reduce__(self):
        """Support pickling Cpv objects.

        >>> import pickle
        >>> from pkgcraft import Cpv
        >>> a = Cpv('cat/pkg-1-r2')
        >>> b = pickle.loads(pickle.dumps(a))
        >>> a == b
        True
        """
        cdef char* c_str = C.pkgcraft_atom_str(self._atom)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return (Cpv, (s,))

    # TODO: move to __del__() when migrating to >=cython-3 since it's not
    # supported in <cython-3 for cdef classes:
    # https://github.com/cython/cython/pull/3804
    def __dealloc__(self):
        C.pkgcraft_atom_free(self._atom)


cdef class Atom(Cpv):
    """Package atom parsing.

    >>> from pkgcraft import Atom

    Simple atom
    >>> a = Atom("cat/pkg")
    >>> a.category
    'cat'
    >>> a.package
    'pkg'

    Complex atom
    >>> a = Atom("=cat/pkg-1-r2:0/2[a,b]::repo")
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
    ['a', 'b']
    >>> a.repo
    'repo'

    Invalid atom
    >>> a = Atom("cat/pkg[foo")
    Traceback (most recent call last):
        ...
    pkgcraft.error.PkgcraftError: parsing failure: invalid atom: "cat/pkg[foo"
      |
    1 | cat/pkg[foo
      |            ^ Expected: one of ",", "]"
      |
    """
    def __cinit__(self):
        self._use = SENTINEL

    def __init__(self, str atom_str, str eapi_str=None):
        atom_bytes = atom_str.encode()
        cdef char* atom = atom_bytes

        cdef char* eapi = NULL
        if eapi_str:
            eapi_bytes = eapi_str.encode()
            eapi = eapi_bytes

        self._eapi = eapi_str
        self._atom = C.pkgcraft_atom(atom, eapi)

        if not self._atom:
            raise PkgcraftError

    @classmethod
    def cached(cls, str atom_str, str eapi_str=None):
        """Return a cached Atom if one exists, otherwise return a new instance."""
        return _cached_atom(cls, atom_str, eapi_str)

    @property
    def blocker(self):
        """Get an atom's blocker.

        >>> from pkgcraft import Atom
        >>> a = Atom("cat/pkg")
        >>> a.blocker is None
        True
        >>> a = Atom("!cat/pkg")
        >>> a.blocker is Blocker.Weak
        True
        >>> a = Atom("!!cat/pkg")
        >>> a.blocker is Blocker.Strong
        True
        """
        cdef int blocker = C.pkgcraft_atom_blocker(self._atom)
        if blocker:
            return Blocker(blocker)
        return None

    @property
    def slot(self):
        """Get an atom's slot.

        >>> from pkgcraft import Atom
        >>> a = Atom("=cat/pkg-1-r2:3/4")
        >>> a.slot
        '3'
        >>> a = Atom("=cat/pkg-1-r2")
        >>> a.slot is None
        True
        """
        cdef char* c_str = C.pkgcraft_atom_slot(self._atom)
        if c_str:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def subslot(self):
        """Get an atom's subslot.

        >>> from pkgcraft import Atom
        >>> a = Atom("=cat/pkg-1-r2:3/4")
        >>> a.subslot
        '4'
        >>> a = Atom("=cat/pkg-1-r2")
        >>> a.subslot is None
        True
        """
        cdef char* c_str = C.pkgcraft_atom_subslot(self._atom)
        if c_str:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def slot_op(self):
        """Get an atom's slot operator.

        >>> from pkgcraft import Atom
        >>> a = Atom("=cat/pkg-1-r2:=")
        >>> a.slot_op
        '='
        >>> a = Atom("=cat/pkg-1-r2")
        >>> a.slot_op is None
        True
        """
        cdef char* c_str = C.pkgcraft_atom_slot_op(self._atom)
        if c_str:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def use(self):
        """Get an atom's USE deps.

        >>> from pkgcraft import Atom
        >>> a = Atom("=cat/pkg-1-r2[a,b,c]")
        >>> a.use
        ['a', 'b', 'c']
        >>> a = Atom("=cat/pkg-1-r2")
        >>> a.use is None
        True
        """
        cdef char **array
        cdef size_t length
        cdef list l = []

        if self._use is SENTINEL:
            array = C.pkgcraft_atom_use_deps(self._atom, &length)
            if array:
                self._use = [array[i].decode() for i in range(length)]
                C.pkgcraft_str_array_free(array, length)
            else:
                self._use = None
        return self._use

    @property
    def repo(self):
        """Get an atom's repo.

        >>> from pkgcraft import Atom
        >>> a = Atom("=cat/pkg-1-r2::repo")
        >>> a.repo
        'repo'
        >>> a = Atom("=cat/pkg-1-r2")
        >>> a.repo is None
        True
        """
        cdef char* c_str = C.pkgcraft_atom_repo(self._atom)
        if c_str:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def cpv(self):
        """Get the concatenated string of an atom's category, package, and version.

        >>> from pkgcraft import Atom
        >>> a = Atom("=cat/pkg-1-r2")
        >>> a.cpv
        'cat/pkg-1-r2'
        """
        cdef char* c_str = C.pkgcraft_atom_cpv(self._atom)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __reduce__(self):
        """Support pickling Atom objects.

        >>> import pickle
        >>> from pkgcraft import Atom
        >>> a = Atom('=cat/pkg-1-r2:0/2=[a,b,c]')
        >>> b = pickle.loads(pickle.dumps(a))
        >>> a == b
        True
        """
        cdef char* c_str = C.pkgcraft_atom_str(self._atom)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return (Atom, (s, self._eapi))
