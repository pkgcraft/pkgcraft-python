from types import MappingProxyType

cimport cython

from . cimport pkgcraft_c as C
from .error cimport _IndirectInit

from .error import PkgcraftError
from .set import OrderedFrozenSet

EAPIS_OFFICIAL = get_official_eapis()
EAPI_LATEST = next(reversed(EAPIS_OFFICIAL.values()))
EAPIS = get_eapis()


cpdef Eapi eapi_from_obj(object obj):
    """Try to convert an object to an Eapi object."""
    if isinstance(obj, Eapi):
        return obj
    elif isinstance(obj, str):
        try:
            return EAPIS[obj]
        except KeyError:
            raise ValueError(f'unknown EAPI: {obj}')
    else:
        raise TypeError(f'{obj.__class__.__name__!r} unsupported Eapi type')


cdef list eapis_to_list(const C.Eapi **c_eapis, size_t length, int start=0):
    """Convert an array of Eapi pointers to a list of Eapi objects."""
    eapis = []
    for i in range(start, length):
        eapis.append(eapi_from_ptr(c_eapis[i]))
    return eapis


cdef object get_official_eapis():
    """Get the mapping of all official EAPIs."""
    cdef size_t length
    eapis = C.pkgcraft_eapis_official(&length)
    d = {str(eapi): eapi for eapi in eapis_to_list(eapis, length)}
    C.pkgcraft_eapis_free(eapis, length)

    # set global variables for each official EAPI, e.g. EAPI0, EAPI1, ...
    for k, v in d.items():
        globals()[f'EAPI{k}'] = v

    return MappingProxyType(d)


cdef object get_eapis():
    """Get the mapping of all known EAPIs."""
    cdef size_t length
    d = EAPIS_OFFICIAL.copy()
    eapis = C.pkgcraft_eapis(&length)
    d.update((str(eapi), eapi) for eapi in eapis_to_list(eapis, length, start=len(d)))
    C.pkgcraft_eapis_free(eapis, length)
    return MappingProxyType(d)


cdef Eapi eapi_from_ptr(const C.Eapi *ptr):
    """Create an Eapi from a pointer."""
    obj = <Eapi>Eapi.__new__(Eapi)
    obj.ptr = ptr
    c_str = C.pkgcraft_eapi_as_str(ptr)
    id = c_str.decode()
    C.pkgcraft_str_free(c_str)
    obj._id = id
    return obj


@cython.final
cdef class Eapi(_IndirectInit):

    @staticmethod
    cdef Eapi from_ptr(const C.Eapi *ptr):
        """Return a known Eapi object for a given pointer."""
        c_str = C.pkgcraft_eapi_as_str(ptr)
        id = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return EAPIS[id]

    @staticmethod
    def range(str s not None):
        """Convert EAPI range into an ordered set of Eapi objects.

        >>> from pkgcraft.eapi import Eapi, EAPI3, EAPI4, EAPIS, EAPIS_OFFICIAL

        >>> Eapi.range('..') == set(EAPIS.values())
        True
        >>> Eapi.range('..2') == {EAPI0, EAPI1}
        True
        >>> Eapi.range('3..4') == {EAPI3}
        True
        >>> Eapi.range('3..=4') == {EAPI3, EAPI4}
        True
        >>> Eapi.range('..9999')
        Traceback (most recent call last):
            ...
        pkgcraft.error.PkgcraftError: invalid EAPI range: ..9999
        """
        cdef size_t length
        c_eapis = C.pkgcraft_eapis_range(s.encode(), &length)
        if c_eapis is NULL:
            raise PkgcraftError
        eapis = eapis_to_list(c_eapis, length)
        C.pkgcraft_eapis_free(c_eapis, length)
        return OrderedFrozenSet(eapis)

    def has(self, str s not None):
        """Check if an EAPI has a given feature.

        >>> from pkgcraft.eapi import EAPI5

        existing feature
        >>> EAPI5.has('subslots')
        True

        newer feature not existing in EAPI 5
        >>> EAPI5.has('nonfatal_die')
        False

        nonexistent feature
        >>> EAPI5.has('nonexistent')
        False
        """
        return C.pkgcraft_eapi_has(self.ptr, s.encode())

    @property
    def dep_keys(self):
        """Get an EAPI's dependency keys."""
        cdef size_t length
        if self._dep_keys is None:
            c_keys = C.pkgcraft_eapi_dep_keys(self.ptr, &length)
            self._dep_keys = frozenset(c_keys[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(c_keys, length)
        return self._dep_keys

    @property
    def metadata_keys(self):
        """Get an EAPI's metadata keys."""
        cdef size_t length
        if self._metadata_keys is None:
            c_keys = C.pkgcraft_eapi_metadata_keys(self.ptr, &length)
            self._metadata_keys = frozenset(c_keys[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(c_keys, length)
        return self._metadata_keys

    def __lt__(self, other):
        if isinstance(other, Eapi):
            return C.pkgcraft_eapi_cmp(self.ptr, (<Eapi>other).ptr) == -1
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, Eapi):
            return C.pkgcraft_eapi_cmp(self.ptr, (<Eapi>other).ptr) <= 0
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, Eapi):
            return C.pkgcraft_eapi_cmp(self.ptr, (<Eapi>other).ptr) == 0
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, Eapi):
            return C.pkgcraft_eapi_cmp(self.ptr, (<Eapi>other).ptr) != 0
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, Eapi):
            return C.pkgcraft_eapi_cmp(self.ptr, (<Eapi>other).ptr) >= 0
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, Eapi):
            return C.pkgcraft_eapi_cmp(self.ptr, (<Eapi>other).ptr) == 1
        return NotImplemented

    def __str__(self):
        return self._id

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        if not self._hash:
            self._hash = C.pkgcraft_eapi_hash(self.ptr)
        return self._hash

    def __reduce__(self):
        return eapi_from_obj, (self._id,)
