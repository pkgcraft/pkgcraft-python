from types import MappingProxyType

from . cimport pkgcraft_c as C
from .error import PkgcraftError

EAPIS_OFFICIAL = get_official_eapis()
EAPI_LATEST = next(reversed(EAPIS_OFFICIAL.values()))
EAPIS = get_eapis()


cdef object get_official_eapis():
    cdef size_t length
    cdef const C.Eapi **eapis = C.pkgcraft_eapis_official(&length)
    cdef dict d = {}

    for i in range(length):
        c_str = C.pkgcraft_eapi_as_str(eapis[i])
        id = c_str.decode()
        C.pkgcraft_str_free(c_str)
        d[id] = Eapi.from_ptr(eapis[i], id)

    C.pkgcraft_eapis_free(eapis, length)
    return MappingProxyType(d)


cdef object get_eapis():
    cdef size_t length
    cdef const C.Eapi **eapis = C.pkgcraft_eapis(&length)
    cdef dict d = EAPIS_OFFICIAL.copy()

    for i in range(len(d) - 1, length):
        c_str = C.pkgcraft_eapi_as_str(eapis[i])
        id = c_str.decode()
        C.pkgcraft_str_free(c_str)
        d[id] = Eapi.from_ptr(eapis[i], id)

    C.pkgcraft_eapis_free(eapis, length)
    return MappingProxyType(d)


cdef class Eapi:

    def __init__(self):
        raise RuntimeError(f"{self.__class__.__name__} class doesn't support manual construction")

    @staticmethod
    cdef Eapi from_ptr(const C.Eapi *eapi, str id):
        """Create instance from a borrowed pointer."""
        obj = <Eapi>Eapi.__new__(Eapi)
        obj._eapi = eapi
        obj._id = id
        return obj

    @staticmethod
    def range(str s not None):
        """Convert EAPI range into the corresponding list of Eapi objects."""
        cdef size_t length
        cdef const C.Eapi **eapis
        cdef dict d = {}

        eapi_range_bytes = s.encode()
        cdef char *eapi_range_p = eapi_range_bytes
        eapis = C.pkgcraft_eapis_range(eapi_range_p, &length)

        for i in range(length):
            c_str = C.pkgcraft_eapi_as_str(eapis[i])
            id = c_str.decode()
            C.pkgcraft_str_free(c_str)
            d[id] = Eapi.from_ptr(eapis[i], id)

        C.pkgcraft_eapis_free(eapis, length)
        return MappingProxyType(d)

    @staticmethod
    def get(str id not None):
        """Get an EAPI given its identifier."""
        try:
            return EAPIS[id]
        except KeyError:
            raise PkgcraftError(f'unknown or invalid EAPI: {id}')

    def has(self, str feature not None):
        """Check if an EAPI has a given feature."""
        feature_bytes = feature.encode()
        cdef char *feature_p = feature_bytes
        return C.pkgcraft_eapi_has(self._eapi, feature_p)

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
        cdef size_t addr = <size_t>&self._eapi
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __hash__(self):
        if not self._hash:
            self._hash = C.pkgcraft_eapi_hash(self._eapi)
        return self._hash
