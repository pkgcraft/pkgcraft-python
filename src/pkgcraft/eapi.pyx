from types import MappingProxyType

cimport cython

from . cimport C
from ._misc cimport cstring_iter, cstring_to_str
from .error cimport Indirect
from .types cimport OrderedFrozenSet

from .error import PkgcraftError

EAPIS_OFFICIAL = get_official_eapis()
EAPIS = get_eapis()


cdef get_official_eapis():
    """Get the mapping of all official EAPIs."""
    cdef size_t length
    c_eapis = C.pkgcraft_eapis_official(&length)
    eapis = [Eapi.from_ptr(c_eapis[i], init=True) for i in range(length)]
    d = {str(eapi): eapi for eapi in eapis}
    C.pkgcraft_array_free(<void **>c_eapis, length)

    # set global variables for official EAPIs
    globals()['EAPI_LATEST_OFFICIAL'] = eapis[-1]
    for k, v in d.items():
        globals()[f'EAPI{k}'] = v

    return MappingProxyType(d)


cdef get_eapis():
    """Get the mapping of all known EAPIs."""
    cdef size_t length
    d = EAPIS_OFFICIAL.copy()
    c_eapis = C.pkgcraft_eapis(&length)
    eapis = [Eapi.from_ptr(c_eapis[i], init=True) for i in range(len(d), length)]
    globals()['EAPI_LATEST'] = eapis[-1]
    d.update((str(eapi), eapi) for eapi in eapis)
    C.pkgcraft_array_free(<void **>c_eapis, length)
    return MappingProxyType(d)


cpdef OrderedFrozenSet eapi_range(s: str):
    """Convert EAPI range into an ordered set of Eapi objects.

    >>> from pkgcraft.eapi import *
    >>> eapi_range('..') == set(EAPIS.values())
    True
    >>> eapi_range('..6') == {EAPI5}
    True
    >>> eapi_range('..=6') == {EAPI5, EAPI6}
    True
    >>> eapi_range('7..8') == {EAPI7}
    True
    >>> eapi_range('8..8') == set()
    True
    >>> eapi_range('7..=8') == {EAPI7, EAPI8}
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
        id = cstring_to_str(C.pkgcraft_eapi_as_str(c_eapis[i]))
        eapis.append(EAPIS[id])

    C.pkgcraft_array_free(<void **>c_eapis, length)
    return OrderedFrozenSet(eapis)


@cython.final
cdef class Eapi(Indirect):

    @staticmethod
    cdef Eapi from_ptr(const C.Eapi *ptr, bint init=False):
        """Create an Eapi object from a pointer."""
        cdef Eapi eapi

        if init:
            eapi = <Eapi>Eapi.__new__(Eapi)
            eapi.ptr = ptr
            eapi.id = cstring_to_str(C.pkgcraft_eapi_as_str(ptr))
            eapi.hash = C.pkgcraft_eapi_hash(ptr)
        else:
            id = cstring_to_str(C.pkgcraft_eapi_as_str(ptr))
            eapi = EAPIS[id]

        return eapi

    @staticmethod
    cdef Eapi _from_obj(object obj):
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

    @staticmethod
    def from_obj(object obj):
        """Try to convert an object to an Eapi object."""
        return Eapi._from_obj(obj)

    @staticmethod
    def parse(s: str, raised=False):
        """Determine if a string is a valid EAPI.

        This avoids any string allocations, only returning the validity status.

        Args:
            s: the string to parse
            raised: if True, raise an exception when invalid

        Returns:
            bool: True if the given string represents a valid EAPI, otherwise False.

        Raises:
            PkgcraftError: on failure if the raised parameter is set to True

        >>> from pkgcraft.eapi import Eapi
        >>> Eapi.parse('01')
        True
        >>> Eapi.parse('@1')
        False
        """
        valid = C.pkgcraft_eapi_parse(s.encode()) is not NULL
        if not valid and raised:
            raise PkgcraftError
        return valid

    def has(self, s: str):
        """Check if an EAPI has a given feature.

        See https://docs.rs/pkgcraft/latest/pkgcraft/eapi/enum.Feature.html for
        the full list of supported EAPI features.

        existing feature:

        >>> from pkgcraft.eapi import EAPI_LATEST_OFFICIAL
        >>> EAPI_LATEST_OFFICIAL.has('UsevTwoArgs')
        True

        feature not existing in official EAPIs:

        >>> EAPI_LATEST_OFFICIAL.has('RepoIds')
        False

        nonexistent feature:

        >>> EAPI_LATEST_OFFICIAL.has('nonexistent')
        False
        """
        return C.pkgcraft_eapi_has(self.ptr, s.encode())

    @property
    def dep_keys(self):
        """Get an EAPI's dependency keys."""
        cdef size_t length
        if self.dep_keys is None:
            c_strs = C.pkgcraft_eapi_dep_keys(self.ptr, &length)
            self.dep_keys = OrderedFrozenSet(cstring_iter(c_strs, length))
        return self.dep_keys

    @property
    def metadata_keys(self):
        """Get an EAPI's metadata keys."""
        cdef size_t length
        if self.metadata_keys is None:
            c_strs = C.pkgcraft_eapi_metadata_keys(self.ptr, &length)
            self.metadata_keys = OrderedFrozenSet(cstring_iter(c_strs, length))
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
        return Eapi.from_obj, (self.id,)
