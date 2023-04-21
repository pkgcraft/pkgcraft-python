from types import MappingProxyType

cimport cython

from . cimport pkgcraft_c as C
from ._misc cimport ptr_to_str
from .error cimport _IndirectInit

from .error import PkgcraftError
from .types import OrderedFrozenSet

EAPIS_OFFICIAL = get_official_eapis()
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
    c_eapis = C.pkgcraft_eapis_official(&length)
    eapis = eapis_to_list(c_eapis, length)
    d = {str(eapi): eapi for eapi in eapis}
    C.pkgcraft_eapis_free(c_eapis, length)

    # set global variables for each official EAPIs
    globals()['EAPI_LATEST_OFFICIAL'] = eapis[-1]
    for k, v in d.items():
        globals()[f'EAPI{k}'] = v

    return MappingProxyType(d)


cdef object get_eapis():
    """Get the mapping of all known EAPIs."""
    cdef size_t length
    d = EAPIS_OFFICIAL.copy()
    c_eapis = C.pkgcraft_eapis(&length)
    eapis = eapis_to_list(c_eapis, length, start=len(d))
    globals()['EAPI_LATEST'] = eapis[-1]
    d.update((str(eapi), eapi) for eapi in eapis)
    C.pkgcraft_eapis_free(c_eapis, length)
    return MappingProxyType(d)


cdef Eapi eapi_from_ptr(const C.Eapi *ptr):
    """Create an Eapi from a pointer."""
    obj = <Eapi>Eapi.__new__(Eapi)
    obj.ptr = ptr
    obj.id = ptr_to_str(C.pkgcraft_eapi_as_str(ptr))
    obj.hash = C.pkgcraft_eapi_hash(ptr)
    return obj


def eapi_range(str s not None):
    """Convert EAPI range into an ordered set of Eapi objects.

    >>> from pkgcraft.eapi import eapi_range, EAPI3, EAPI4, EAPIS, EAPIS_OFFICIAL

    >>> eapi_range('..') == set(EAPIS.values())
    True
    >>> eapi_range('..2') == {EAPI0, EAPI1}
    True
    >>> eapi_range('3..4') == {EAPI3}
    True
    >>> eapi_range('3..=4') == {EAPI3, EAPI4}
    True
    >>> eapi_range('..9999')
    Traceback (most recent call last):
        ...
    pkgcraft.error.PkgcraftError: invalid EAPI range: ..9999
    """
    cdef size_t length
    c_eapis = C.pkgcraft_eapis_range(s.encode(), &length)
    if c_eapis is NULL:
        raise PkgcraftError

    eapis = []
    for i in range(0, length):
        id = ptr_to_str(C.pkgcraft_eapi_as_str(c_eapis[i]))
        eapis.append(EAPIS[id])

    C.pkgcraft_eapis_free(c_eapis, length)
    return OrderedFrozenSet(eapis)


@cython.final
cdef class Eapi(_IndirectInit):

    @staticmethod
    cdef Eapi from_ptr(const C.Eapi *ptr):
        """Return a known Eapi object for a given pointer."""
        id = ptr_to_str(C.pkgcraft_eapi_as_str(ptr))
        return EAPIS[id]

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
        if self.dep_keys is None:
            c_keys = C.pkgcraft_eapi_dep_keys(self.ptr, &length)
            self.dep_keys = frozenset(c_keys[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(c_keys, length)
        return self.dep_keys

    @property
    def metadata_keys(self):
        """Get an EAPI's metadata keys."""
        cdef size_t length
        if self.metadata_keys is None:
            c_keys = C.pkgcraft_eapi_metadata_keys(self.ptr, &length)
            self.metadata_keys = frozenset(c_keys[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(c_keys, length)
        return self.metadata_keys

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
        return self.id

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        return self.hash

    def __reduce__(self):
        return eapi_from_obj, (self.id,)
