import functools

from .. cimport pkgcraft_c as C
from .._misc cimport SENTINEL
from .cpv cimport Cpv
from ..error import PkgcraftError

# TODO: merge with Atom.cached function when cython bug is fixed
# https://github.com/cython/cython/issues/1434
@functools.lru_cache(maxsize=10000)
def _cached_atom(cls, atom, eapi=None):
    return cls(atom, eapi)


cdef class Atom(Cpv):
    """Package atom parsing.

    >>> from pkgcraft.atom import Atom

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
    ('a', 'b')
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

    def __init__(self, str atom not None, str eapi=None):
        atom_bytes = atom.encode()
        cdef char* atom_p = atom_bytes

        cdef char* eapi_p = NULL
        if eapi is not None:
            eapi_bytes = eapi.encode()
            eapi_p = eapi_bytes

        self._eapi = eapi
        self._atom = C.pkgcraft_atom(atom_p, eapi_p)

        if self._atom is NULL:
            raise PkgcraftError

    @classmethod
    def cached(cls, str atom not None, str eapi=None):
        """Return a cached Atom if one exists, otherwise return a new instance."""
        return _cached_atom(cls, atom, eapi)

    @property
    def blocker(self):
        """Get an atom's blocker.

        >>> from pkgcraft.atom import Atom
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
        if blocker > 0:
            return Blocker(blocker)
        return None

    @property
    def slot(self):
        """Get an atom's slot.

        >>> from pkgcraft.atom import Atom
        >>> a = Atom("=cat/pkg-1-r2:3/4")
        >>> a.slot
        '3'
        >>> a = Atom("=cat/pkg-1-r2")
        >>> a.slot is None
        True
        """
        cdef char* c_str = C.pkgcraft_atom_slot(self._atom)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def subslot(self):
        """Get an atom's subslot.

        >>> from pkgcraft.atom import Atom
        >>> a = Atom("=cat/pkg-1-r2:3/4")
        >>> a.subslot
        '4'
        >>> a = Atom("=cat/pkg-1-r2")
        >>> a.subslot is None
        True
        """
        cdef char* c_str = C.pkgcraft_atom_subslot(self._atom)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def slot_op(self):
        """Get an atom's slot operator.

        >>> from pkgcraft.atom import Atom
        >>> a = Atom("=cat/pkg-1-r2:=")
        >>> a.slot_op
        '='
        >>> a = Atom("=cat/pkg-1-r2")
        >>> a.slot_op is None
        True
        """
        cdef char* c_str = C.pkgcraft_atom_slot_op(self._atom)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def use(self):
        """Get an atom's USE deps.

        >>> from pkgcraft.atom import Atom
        >>> a = Atom("=cat/pkg-1-r2[a,b,c]")
        >>> a.use
        ('a', 'b', 'c')
        >>> a = Atom("=cat/pkg-1-r2")
        >>> a.use is None
        True
        """
        cdef char **array
        cdef size_t length

        if self._use is SENTINEL:
            array = C.pkgcraft_atom_use_deps(self._atom, &length)
            if array is not NULL:
                self._use = tuple(array[i].decode() for i in range(length))
                C.pkgcraft_str_array_free(array, length)
            else:
                self._use = None
        return self._use

    @property
    def repo(self):
        """Get an atom's repo.

        >>> from pkgcraft.atom import Atom
        >>> a = Atom("=cat/pkg-1-r2::repo")
        >>> a.repo
        'repo'
        >>> a = Atom("=cat/pkg-1-r2")
        >>> a.repo is None
        True
        """
        cdef char* c_str = C.pkgcraft_atom_repo(self._atom)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def cpv(self):
        """Get the concatenated string of an atom's category, package, and version.

        >>> from pkgcraft.atom import Atom
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
        >>> from pkgcraft.atom import Atom
        >>> a = Atom('=cat/pkg-1-r2:0/2=[a,b,c]')
        >>> b = pickle.loads(pickle.dumps(a))
        >>> a == b
        True
        """
        cdef char* c_str = C.pkgcraft_atom_str(self._atom)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return (Atom, (s, self._eapi))
