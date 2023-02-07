from .. cimport pkgcraft_c as C
from ..error cimport _IndirectInit
from . cimport Repo

from ..set import OrderedFrozenSet


cdef class EbuildRepo(Repo):
    """Ebuild package repo."""

    format = C.RepoFormat.REPO_FORMAT_EBUILD

    @property
    def eapi(self):
        """Get an ebuild repo's EAPI."""
        if self._eapi is None:
            self._eapi = Eapi.from_ptr(C.pkgcraft_repo_ebuild_eapi(self.ptr))
        return self._eapi

    @property
    def masters(self):
        """Get an ebuild repo's masters."""
        cdef size_t length
        if self._masters is None:
            repos = C.pkgcraft_repo_ebuild_masters(self.ptr, &length)
            self._masters = tuple(EbuildRepo.from_ptr(repos[i], False) for i in range(length))
        return self._masters

    @property
    def metadata(self):
        """Get an ebuild repo's metadata."""
        if self._metadata is None:
            self._metadata = _Metadata.from_ptr(self.ptr)
        return self._metadata


cdef class _Metadata(_IndirectInit):
    """Ebuild repo metadata."""

    @staticmethod
    cdef _Metadata from_ptr(C.Repo *ptr):
        """Create a Metadata object from a pointer."""
        obj = <_Metadata>_Metadata.__new__(_Metadata)
        obj.ptr = ptr
        return obj

    @property
    def arches(self):
        """Get an ebuild repo's defined arches."""
        cdef size_t length
        if self._arches is None:
            arches = C.pkgcraft_repo_ebuild_metadata_arches(self.ptr, &length)
            self._arches = OrderedFrozenSet(arches[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(arches, length)
        return self._arches

    @property
    def categories(self):
        """Get an ebuild repo's defined categories."""
        cdef size_t length
        if self._categories is None:
            categories = C.pkgcraft_repo_ebuild_metadata_categories(self.ptr, &length)
            self._categories = OrderedFrozenSet(categories[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(categories, length)
        return self._categories
