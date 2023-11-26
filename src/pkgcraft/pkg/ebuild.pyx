from pathlib import Path

cimport cython

from .. cimport C
from .._misc cimport SENTINEL, CStringArray, cstring_iter, cstring_to_str
from ..dep cimport DepSet, MutableDepSet
from ..error cimport Internal
from . cimport Pkg

from ..error import PkgcraftError
from ..types import OrderedFrozenSet


@cython.final
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
        s = cstring_to_str(C.pkgcraft_pkg_ebuild_ebuild(self.ptr))
        if s is not None:
            return s
        raise PkgcraftError

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
            return MutableDepSet.from_ptr(ptr)
        raise PkgcraftError

    @property
    def bdepend(self):
        """Get a package's BDEPEND."""
        if self._bdepend is None:
            ptr = C.pkgcraft_pkg_ebuild_bdepend(self.ptr)
            self._bdepend = DepSet.from_ptr(ptr)
        return self._bdepend

    @property
    def depend(self):
        """Get a package's DEPEND."""
        if self._depend is None:
            ptr = C.pkgcraft_pkg_ebuild_depend(self.ptr)
            self._depend = DepSet.from_ptr(ptr)
        return self._depend

    @property
    def idepend(self):
        """Get a package's IDEPEND."""
        if self._idepend is None:
            ptr = C.pkgcraft_pkg_ebuild_idepend(self.ptr)
            self._idepend = DepSet.from_ptr(ptr)
        return self._idepend

    @property
    def pdepend(self):
        """Get a package's PDEPEND."""
        if self._pdepend is None:
            ptr = C.pkgcraft_pkg_ebuild_pdepend(self.ptr)
            self._pdepend = DepSet.from_ptr(ptr)
        return self._pdepend

    @property
    def rdepend(self):
        """Get a package's RDEPEND."""
        if self._rdepend is None:
            ptr = C.pkgcraft_pkg_ebuild_rdepend(self.ptr)
            self._rdepend = DepSet.from_ptr(ptr)
        return self._rdepend

    @property
    def license(self):
        """Get a package's LICENSE."""
        if self._license is None:
            ptr = C.pkgcraft_pkg_ebuild_license(self.ptr)
            self._license = DepSet.from_ptr(ptr)
        return self._license

    @property
    def properties(self):
        """Get a package's PROPERTIES."""
        if self._properties is None:
            ptr = C.pkgcraft_pkg_ebuild_properties(self.ptr)
            self._properties = DepSet.from_ptr(ptr)
        return self._properties

    @property
    def required_use(self):
        """Get a package's REQUIRED_USE."""
        if self._required_use is None:
            ptr = C.pkgcraft_pkg_ebuild_required_use(self.ptr)
            self._required_use = DepSet.from_ptr(ptr)
        return self._required_use

    @property
    def restrict(self):
        """Get a package's RESTRICT."""
        if self._restrict is None:
            ptr = C.pkgcraft_pkg_ebuild_restrict(self.ptr)
            self._restrict = DepSet.from_ptr(ptr)
        return self._restrict

    @property
    def src_uri(self):
        """Get a package's SRC_URI."""
        if self._src_uri is None:
            ptr = C.pkgcraft_pkg_ebuild_src_uri(self.ptr)
            self._src_uri = DepSet.from_ptr(ptr)
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
            c_strs = C.pkgcraft_pkg_ebuild_keywords(self.ptr, &length)
            self._keywords = OrderedFrozenSet(cstring_iter(c_strs, length))
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
cdef class Maintainer(Internal):
    """Ebuild package maintainer."""

    @staticmethod
    cdef Maintainer from_ptr(C.Maintainer *m):
        """Create a Maintainer from a pointer."""
        inst = <Maintainer>Maintainer.__new__(Maintainer)
        inst.email = m.email.decode()
        inst.name = cstring_to_str(m.name, free=False)
        inst.description = cstring_to_str(m.description, free=False)
        inst.maint_type = m.maint_type.decode()
        inst.proxied = m.proxied.decode()
        return inst

    def __str__(self):
        if self.name is not None:
            s = f'{self.name} <{self.email}>'
        else:
            s = self.email

        if self.description is not None:
            return f'{s} ({self.description})'
        return s

    def __repr__(self):
        name = self.__class__.__name__
        return f"<{name} '{self.email}'>"

    def __hash__(self):
        return hash((self.email, self.name))


@cython.final
cdef class RemoteId(Internal):
    """Ebuild package upstream site."""

    @staticmethod
    cdef RemoteId from_ptr(C.RemoteId *r):
        """Create an RemoteId from a pointer."""
        inst = <RemoteId>RemoteId.__new__(RemoteId)
        inst.site = r.site.decode()
        inst.name = r.name.decode()
        return inst

    def __str__(self):
        return f'{self.site}: {self.name}'

    def __repr__(self):
        name = self.__class__.__name__
        return f"<{name} '{self}'>"


@cython.final
cdef class UpstreamMaintainer(Internal):
    """Upstream package maintainer."""

    @staticmethod
    cdef UpstreamMaintainer from_ptr(C.UpstreamMaintainer *m):
        """Create an UpstreamMaintainer from a pointer."""
        inst = <UpstreamMaintainer>UpstreamMaintainer.__new__(UpstreamMaintainer)
        inst.name = m.name.decode()
        inst.email = cstring_to_str(m.email, free=False)
        inst.status = m.status.decode()
        return inst

    def __str__(self):
        if self.email is not None:
            s = f'{self.name} <{self.email}>'
        else:
            s = self.name

        return f'{s} ({self.status})'

    def __repr__(self):
        name = self.__class__.__name__
        return f"<{name} '{self}'>"


@cython.final
cdef class Upstream(Internal):
    """Ebuild package upstream info."""

    @staticmethod
    cdef Upstream from_ptr(C.Upstream *u):
        """Create an Upstream from a pointer."""
        inst = <Upstream>Upstream.__new__(Upstream)
        inst.remote_ids = tuple(
            RemoteId.from_ptr(u.remote_ids[i]) for i in range(u.remote_ids_len))
        inst.maintainers = tuple(
            UpstreamMaintainer.from_ptr(u.maintainers[i]) for i in range(u.maintainers_len))
        inst.bugs_to = cstring_to_str(u.bugs_to, free=False)
        inst.changelog = cstring_to_str(u.changelog, free=False)
        inst.doc = cstring_to_str(u.doc, free=False)
        C.pkgcraft_pkg_ebuild_upstream_free(u)
        return inst
