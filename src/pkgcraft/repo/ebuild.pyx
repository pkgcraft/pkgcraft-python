cimport cython

from .. cimport C
from .._misc cimport cstring_iter
from ..config cimport Config
from ..error cimport Indirect
from ..types cimport OrderedFrozenSet
from . cimport Repo

from ..error import PkgcraftError


cdef class EbuildRepo(Repo):
    """Ebuild package repo."""

    _format = C.RepoFormat.REPO_FORMAT_EBUILD

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
            self._masters = tuple(Repo.from_ptr(repos[i]) for i in range(length))
        return self._masters

    @property
    def licenses(self):
        """Get an ebuild repo's inherited licenses."""
        cdef size_t length
        if self._licenses is None:
            c_strs = C.pkgcraft_repo_ebuild_licenses(self.ptr, &length)
            self._licenses = OrderedFrozenSet(cstring_iter(c_strs, length))
        return self._licenses

    @property
    def metadata(self):
        """Get an ebuild repo's metadata."""
        if self._metadata is None:
            self._metadata = Metadata.from_ptr(self.ptr)
        return self._metadata

    def configure(self, config: Config):
        """Return a configured repo using the given config."""
        ptr = C.pkgcraft_repo_ebuild_configure(self.ptr, config.ptr)
        return Repo.from_ptr(ptr)

    def metadata_regen(self, int jobs=0, force=False, path=None):
        """Regenerate an ebuild repo's package metadata cache."""
        cache_path = str(path) if path is not None else ""
        if not C.pkgcraft_repo_ebuild_metadata_regen(self.ptr, jobs, force, cache_path.encode()):
            raise PkgcraftError


@cython.final
cdef class Metadata(Indirect):
    """Ebuild repo metadata."""

    @staticmethod
    cdef Metadata from_ptr(C.Repo *ptr):
        """Create a Metadata object from a pointer."""
        inst = <Metadata>Metadata.__new__(Metadata)
        inst.ptr = ptr
        return inst

    @property
    def arches(self):
        """Get an ebuild repo's defined arches."""
        cdef size_t length
        if self._arches is None:
            c_strs = C.pkgcraft_repo_ebuild_metadata_arches(self.ptr, &length)
            self._arches = OrderedFrozenSet(cstring_iter(c_strs, length))
        return self._arches

    @property
    def categories(self):
        """Get an ebuild repo's defined categories."""
        cdef size_t length
        if self._categories is None:
            c_strs = C.pkgcraft_repo_ebuild_metadata_categories(self.ptr, &length)
            self._categories = OrderedFrozenSet(cstring_iter(c_strs, length))
        return self._categories

    @property
    def licenses(self):
        """Get an ebuild repo's defined licenses."""
        cdef size_t length
        if self._licenses is None:
            c_strs = C.pkgcraft_repo_ebuild_metadata_licenses(self.ptr, &length)
            self._licenses = OrderedFrozenSet(cstring_iter(c_strs, length))
        return self._licenses


@cython.final
cdef class ConfiguredRepo(EbuildRepo):
    """Configured ebuild package repo."""

    _format = C.RepoFormat.REPO_FORMAT_CONFIGURED
