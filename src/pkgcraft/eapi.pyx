from types import MappingProxyType

from . cimport pkgcraft_c as C
from .error import IndirectInit, PkgcraftError

EAPIS_OFFICIAL = get_official_eapis()
EAPI_LATEST = next(reversed(EAPIS_OFFICIAL.values()))
EAPIS = get_eapis()


cdef dict eapis_to_dict(const C.Eapi **eapis, size_t length, int start=0):
    """Convert an array of Eapi pointers to an (id, Eapi) mapping."""
    d = {}
    for i in range(start, length):
        c_str = C.pkgcraft_eapi_as_str(eapis[i])
        id = c_str.decode()
        C.pkgcraft_str_free(c_str)
        d[id] = Eapi.from_ptr(eapis[i], id)
    return d


cdef object get_official_eapis():
    """Get the mapping of all official EAPIs."""
    cdef size_t length
    eapis = C.pkgcraft_eapis_official(&length)
    d = eapis_to_dict(eapis, length)
    C.pkgcraft_eapis_free(eapis, length)
    return MappingProxyType(d)


cdef object get_eapis():
    """Get the mapping of all known EAPIs."""
    cdef size_t length
    d = EAPIS_OFFICIAL.copy()
    eapis = C.pkgcraft_eapis(&length)
    d.update(eapis_to_dict(eapis, length, start=len(d) - 1))
    C.pkgcraft_eapis_free(eapis, length)
    return MappingProxyType(d)


cdef class Eapi:

    def __init__(self):
        raise IndirectInit(self)

    @staticmethod
    cdef Eapi from_ptr(const C.Eapi *eapi, str id):
        """Create instance from a borrowed pointer."""
        obj = <Eapi>Eapi.__new__(Eapi)
        obj._eapi = eapi
        obj._id = id
        return obj

    @staticmethod
    def range(s):
        """Convert EAPI range into an ordered mapping of Eapi objects."""
        cdef size_t length
        eapi_range = (<str?>s).encode()
        eapis = C.pkgcraft_eapis_range(eapi_range, &length)
        d = eapis_to_dict(eapis, length)
        C.pkgcraft_eapis_free(eapis, length)
        return MappingProxyType(d)

    @staticmethod
    def get(id):
        """Get an EAPI given its identifier."""
        try:
            return EAPIS[id]
        except KeyError:
            raise PkgcraftError(f'unknown or invalid EAPI: {id}')

    def has(self, s):
        """Check if an EAPI has a given feature."""
        feature = (<str?>s).encode()
        return C.pkgcraft_eapi_has(self._eapi, feature)

    def __lt__(self, Eapi other):
        return C.pkgcraft_eapi_cmp(self._eapi, other._eapi) == -1

    def __le__(self, Eapi other):
        return C.pkgcraft_eapi_cmp(self._eapi, other._eapi) <= 0

    def __eq__(self, Eapi other):
        return C.pkgcraft_eapi_cmp(self._eapi, other._eapi) == 0

    def __ne__(self, Eapi other):
        return C.pkgcraft_eapi_cmp(self._eapi, other._eapi) != 0

    def __gt__(self, Eapi other):
        return C.pkgcraft_eapi_cmp(self._eapi, other._eapi) == 1

    def __ge__(self, Eapi other):
        return C.pkgcraft_eapi_cmp(self._eapi, other._eapi) >= 0

    def __str__(self):
        return self._id

    def __repr__(self):
        addr = <size_t>&self._eapi
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        if not self._hash:
            self._hash = C.pkgcraft_eapi_hash(self._eapi)
        return self._hash
