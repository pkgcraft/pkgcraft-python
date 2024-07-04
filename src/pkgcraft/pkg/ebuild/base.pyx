from pathlib import Path

cimport cython

from ... cimport C
from ..._misc cimport SENTINEL, CStringArray, cstring_iter, cstring_to_str
from ...dep cimport DependencySet, MutableDependencySet
from ...types cimport OrderedFrozenSet
from .. cimport Pkg
from . cimport Keyword, Maintainer, Upstream

from ...error import PkgcraftError


cdef class EbuildPkg(Pkg):
    """Generic ebuild package."""

    def __cinit__(self):
        self._upstream = SENTINEL

    @property
    def path(self):
        """Get a package's path."""
        return Path(cstring_to_str(C.pkgcraft_pkg_ebuild_path(self.ptr)))

    @property
    def ebuild(self):
        """Get a package's ebuild file content."""
        if ptr := C.pkgcraft_pkg_ebuild_ebuild(self.ptr):
            return cstring_to_str(ptr)
        raise PkgcraftError

    @property
    def deprecated(self):
        """Get a package's deprecated status."""
        return C.pkgcraft_pkg_ebuild_deprecated(self.ptr)

    @property
    def live(self):
        """Get a package's live status."""
        return C.pkgcraft_pkg_ebuild_live(self.ptr)

    @property
    def masked(self):
        """Get a package's masked status."""
        return C.pkgcraft_pkg_ebuild_masked(self.ptr)

    @property
    def description(self):
        """Get a package's description."""
        if self._description is None:
            self._description = cstring_to_str(C.pkgcraft_pkg_ebuild_description(self.ptr))
        return self._description

    @property
    def slot(self):
        """Get a package's slot."""
        if self._slot is None:
            self._slot = cstring_to_str(C.pkgcraft_pkg_ebuild_slot(self.ptr))
        return self._slot

    @property
    def subslot(self):
        """Get a package's subslot."""
        if self._subslot is None:
            self._subslot = cstring_to_str(C.pkgcraft_pkg_ebuild_subslot(self.ptr))
        return self._subslot

    def dependencies(self, *keys):
        """Get a package's dependencies for the given descriptors.

        Returns all dependencies when no descriptors are passed.
        """
        array = CStringArray(keys)
        if ptr := C.pkgcraft_pkg_ebuild_dependencies(self.ptr, array.ptr, len(array)):
            return MutableDependencySet.from_ptr(ptr)
        raise PkgcraftError

    @property
    def bdepend(self):
        """Get a package's BDEPEND."""
        if self._bdepend is None:
            ptr = C.pkgcraft_pkg_ebuild_bdepend(self.ptr)
            self._bdepend = DependencySet.from_ptr(ptr)
        return self._bdepend

    @property
    def depend(self):
        """Get a package's DEPEND."""
        if self._depend is None:
            ptr = C.pkgcraft_pkg_ebuild_depend(self.ptr)
            self._depend = DependencySet.from_ptr(ptr)
        return self._depend

    @property
    def idepend(self):
        """Get a package's IDEPEND."""
        if self._idepend is None:
            ptr = C.pkgcraft_pkg_ebuild_idepend(self.ptr)
            self._idepend = DependencySet.from_ptr(ptr)
        return self._idepend

    @property
    def pdepend(self):
        """Get a package's PDEPEND."""
        if self._pdepend is None:
            ptr = C.pkgcraft_pkg_ebuild_pdepend(self.ptr)
            self._pdepend = DependencySet.from_ptr(ptr)
        return self._pdepend

    @property
    def rdepend(self):
        """Get a package's RDEPEND."""
        if self._rdepend is None:
            ptr = C.pkgcraft_pkg_ebuild_rdepend(self.ptr)
            self._rdepend = DependencySet.from_ptr(ptr)
        return self._rdepend

    @property
    def license(self):
        """Get a package's LICENSE."""
        if self._license is None:
            ptr = C.pkgcraft_pkg_ebuild_license(self.ptr)
            self._license = DependencySet.from_ptr(ptr)
        return self._license

    @property
    def properties(self):
        """Get a package's PROPERTIES."""
        if self._properties is None:
            ptr = C.pkgcraft_pkg_ebuild_properties(self.ptr)
            self._properties = DependencySet.from_ptr(ptr)
        return self._properties

    @property
    def required_use(self):
        """Get a package's REQUIRED_USE."""
        if self._required_use is None:
            ptr = C.pkgcraft_pkg_ebuild_required_use(self.ptr)
            self._required_use = DependencySet.from_ptr(ptr)
        return self._required_use

    @property
    def restrict(self):
        """Get a package's RESTRICT."""
        if self._restrict is None:
            ptr = C.pkgcraft_pkg_ebuild_restrict(self.ptr)
            self._restrict = DependencySet.from_ptr(ptr)
        return self._restrict

    @property
    def src_uri(self):
        """Get a package's SRC_URI."""
        if self._src_uri is None:
            ptr = C.pkgcraft_pkg_ebuild_src_uri(self.ptr)
            self._src_uri = DependencySet.from_ptr(ptr)
        return self._src_uri

    @property
    def defined_phases(self):
        """Get a package's defined phases."""
        cdef size_t length
        if self._defined_phases is None:
            c_strs = C.pkgcraft_pkg_ebuild_defined_phases(self.ptr, &length)
            self._defined_phases = OrderedFrozenSet(cstring_iter(c_strs, length))
        return self._defined_phases

    @property
    def homepage(self):
        """Get a package's homepage."""
        cdef size_t length
        if self._homepage is None:
            c_strs = C.pkgcraft_pkg_ebuild_homepage(self.ptr, &length)
            self._homepage = OrderedFrozenSet(cstring_iter(c_strs, length))
        return self._homepage

    @property
    def keywords(self):
        """Get a package's keywords."""
        cdef size_t length
        if self._keywords is None:
            ptrs = C.pkgcraft_pkg_ebuild_keywords(self.ptr, &length)
            self._keywords = OrderedFrozenSet(
                Keyword.from_ptr(ptrs[i]) for i in range(length))
            C.pkgcraft_array_free(<void **>ptrs, length)
        return self._keywords

    @property
    def iuse(self):
        """Get a package's USE flags."""
        cdef size_t length
        if self._iuse is None:
            c_strs = C.pkgcraft_pkg_ebuild_iuse(self.ptr, &length)
            self._iuse = OrderedFrozenSet(cstring_iter(c_strs, length))
        return self._iuse

    @property
    def inherit(self):
        """Get a package's ordered set of directly inherited eclasses."""
        cdef size_t length
        if self._inherit is None:
            c_strs = C.pkgcraft_pkg_ebuild_inherit(self.ptr, &length)
            self._inherit = OrderedFrozenSet(cstring_iter(c_strs, length))
        return self._inherit

    @property
    def inherited(self):
        """Get a package's ordered set of inherited eclasses."""
        cdef size_t length
        if self._inherited is None:
            c_strs = C.pkgcraft_pkg_ebuild_inherited(self.ptr, &length)
            self._inherited = OrderedFrozenSet(cstring_iter(c_strs, length))
        return self._inherited

    @property
    def long_description(self):
        """Get a package's long description."""
        return cstring_to_str(C.pkgcraft_pkg_ebuild_long_description(self.ptr))

    @property
    def maintainers(self):
        """Get a package's maintainers."""
        cdef size_t length
        if self._maintainers is None:
            maintainers = C.pkgcraft_pkg_ebuild_maintainers(self.ptr, &length)
            self._maintainers = OrderedFrozenSet(
                Maintainer.from_ptr(maintainers[i]) for i in range(length))
            C.pkgcraft_pkg_ebuild_maintainers_free(maintainers, length)
        return self._maintainers

    @property
    def upstream(self):
        """Get a package's upstream info."""
        if self._upstream is SENTINEL:
            if ptr := C.pkgcraft_pkg_ebuild_upstream(self.ptr):
                self._upstream = Upstream.from_ptr(ptr)
            else:
                self._upstream = None
        return self._upstream


@cython.final
cdef class ConfiguredPkg(EbuildPkg):
    """Configured ebuild package."""
