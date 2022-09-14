from .. cimport pkgcraft_c as C
from .._misc cimport SENTINEL
from .version cimport Version
from ..error import InvalidCpv


cdef class Cpv:
    """CPV string parsing.

    >>> from pkgcraft.atom import Cpv

    Valid CPV
    >>> cpv = Cpv("cat/pkg-1-r2")
    >>> cpv.category
    'cat'
    >>> cpv.package
    'pkg'
    >>> str(cpv.version)
    '1-r2'
    """
    def __cinit__(self):
        self._version = SENTINEL

    def __init__(self, str atom not None):
        self._atom = C.pkgcraft_cpv(atom.encode())
        if self._atom is NULL:
            raise InvalidCpv

    @staticmethod
    cdef Cpv from_ptr(const C.Atom *atom):
        """Create instance from a borrowed pointer."""
        obj = <Cpv>Cpv.__new__(Cpv)
        obj._atom = <C.Atom *>atom
        obj._ref = True
        return obj

    @property
    def category(self):
        """Get an atom's category.

        >>> from pkgcraft.atom import Cpv
        >>> a = Cpv("cat/pkg-1-r2")
        >>> a.category
        'cat'
        """
        cdef char *c_str
        if self._category is None:
            c_str = C.pkgcraft_atom_category(self._atom)
            self._category = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._category

    @property
    def package(self):
        """Get an atom's package.

        >>> from pkgcraft.atom import Cpv
        >>> a = Cpv("cat/pkg-1-r2")
        >>> a.package
        'pkg'
        """
        cdef char *c_str
        if self._package is None:
            c_str = C.pkgcraft_atom_package(self._atom)
            self._package = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._package

    @property
    def version(self):
        """Get an atom's version.

        >>> from pkgcraft.atom import Cpv
        >>> a = Cpv("cat/pkg-1-r2")
        >>> str(a.version)
        '1-r2'
        """
        cdef const C.AtomVersion *ver

        if self._version is SENTINEL:
            ver = C.pkgcraft_atom_version(self._atom)
            self._version = Version.from_ptr(ver) if ver is not NULL else None
        return self._version

    @property
    def revision(self):
        """Get an atom's revision.

        >>> from pkgcraft.atom import Cpv
        >>> a = Cpv("cat/pkg-1-r2")
        >>> a.revision
        '2'
        >>> a = Cpv("cat/pkg-1")
        >>> a.revision
        '0'
        """
        cdef char *c_str = C.pkgcraft_atom_revision(self._atom)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    @property
    def key(self):
        """Get the concatenated string of an atom's category and package.

        >>> from pkgcraft.atom import Cpv
        >>> a = Cpv("cat/pkg-1-r2")
        >>> a.key
        'cat/pkg'
        """
        cdef char *c_str = C.pkgcraft_atom_key(self._atom)
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
        cdef char *c_str = C.pkgcraft_atom_str(self._atom)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __repr__(self):
        cdef size_t addr = <size_t>&self._atom
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        if not self._hash:
            self._hash = C.pkgcraft_atom_hash(self._atom)
        return self._hash

    def __reduce__(self):
        """Support pickling Cpv objects."""
        cdef char *c_str = C.pkgcraft_atom_str(self._atom)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return (self.__class__, (s,))

    # TODO: move to __del__() when migrating to >=cython-3 since it's not
    # supported in <cython-3 for cdef classes:
    # https://github.com/cython/cython/pull/3804
    def __dealloc__(self):
        if not self._ref:
            C.pkgcraft_atom_free(self._atom)
