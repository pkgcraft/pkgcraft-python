from . cimport pkgcraft_c as C
from .error import PkgcraftError


cdef class Eapi:

    def __init__(self, str eapi not None):
        eapi_bytes = eapi.encode()
        cdef char* eapi_p = eapi_bytes

        self._eapi = C.pkgcraft_get_eapi(eapi_p)

        if self._eapi is NULL:
            raise PkgcraftError

        self.id = eapi

    def has(self, str feature not None):
        """Check if an EAPI has a given feature."""
        feature_bytes = feature.encode()
        cdef char* feature_p = feature_bytes
        return C.pkgcraft_eapi_has(self._eapi, feature_p)

    def __str__(self):
        return self.id
