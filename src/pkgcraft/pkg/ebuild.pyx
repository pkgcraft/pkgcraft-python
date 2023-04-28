from pathlib import Path

cimport cython

from .. cimport pkgcraft_c as C
from .._misc cimport SENTINEL, StrArray, ptr_to_str
from ..dep cimport Dependencies, License, Properties, RequiredUse, Restrict, SrcUri
from . cimport Pkg

from ..error import PkgcraftError
from ..types import OrderedFrozenSet


@cython.final
cdef class EbuildPkg(Pkg):
    """Generic ebuild package."""

    def __cinit__(self):
        self._depend = SENTINEL
        self._bdepend = SENTINEL
        self._idepend = SENTINEL
        self._pdepend = SENTINEL
        self._rdepend = SENTINEL
        self._license = SENTINEL
        self._properties = SENTINEL
        self._required_use = SENTINEL
        self._restrict = SENTINEL
        self._src_uri = SENTINEL
        self._upstream = SENTINEL

    @property
    def path(self):
        """Get a package's path."""
        return Path(ptr_to_str(C.pkgcraft_pkg_ebuild_path(self.ptr)))

    @property
    def ebuild(self):
        """Get a package's ebuild file content."""
        s = ptr_to_str(C.pkgcraft_pkg_ebuild_ebuild(self.ptr))
        if s is None:
            raise PkgcraftError
        return s

    @property
    def description(self):
        """Get a package's description."""
        if self._description is None:
            self._description = ptr_to_str(C.pkgcraft_pkg_ebuild_description(self.ptr))
        return self._description

    @property
    def slot(self):
        """Get a package's slot."""
        if self._slot is None:
            self._slot = ptr_to_str(C.pkgcraft_pkg_ebuild_slot(self.ptr))
        return self._slot

    @property
    def subslot(self):
        """Get a package's subslot."""
        if self._subslot is None:
            self._subslot = ptr_to_str(C.pkgcraft_pkg_ebuild_subslot(self.ptr))
        return self._subslot

    def dependencies(self, *keys):
        """Get a package's dependencies for the given descriptors.

        Returns a DepSet encompassing all dependencies when no descriptors are passed.
        """
        array = StrArray(keys)
        ptr = C.pkgcraft_pkg_ebuild_dependencies(self.ptr, array.ptr, len(array))
        if ptr is NULL:
            raise PkgcraftError
        return Dependencies.from_ptr(ptr)

    @property
    def bdepend(self):
        """Get a package's BDEPEND."""
        if self._bdepend is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_bdepend(self.ptr)
            self._bdepend = Dependencies.from_ptr(ptr)
        return self._bdepend

    @property
    def depend(self):
        """Get a package's DEPEND."""
        if self._depend is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_depend(self.ptr)
            self._depend = Dependencies.from_ptr(ptr)
        return self._depend

    @property
    def idepend(self):
        """Get a package's IDEPEND."""
        if self._idepend is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_idepend(self.ptr)
            self._idepend = Dependencies.from_ptr(ptr)
        return self._idepend

    @property
    def pdepend(self):
        """Get a package's PDEPEND."""
        if self._pdepend is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_pdepend(self.ptr)
            self._pdepend = Dependencies.from_ptr(ptr)
        return self._pdepend

    @property
    def rdepend(self):
        """Get a package's RDEPEND."""
        if self._rdepend is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_rdepend(self.ptr)
            self._rdepend = Dependencies.from_ptr(ptr)
        return self._rdepend

    @property
    def license(self):
        """Get a package's LICENSE."""
        if self._license is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_license(self.ptr)
            self._license = License.from_ptr(ptr)
        return self._license

    @property
    def properties(self):
        """Get a package's PROPERTIES."""
        if self._properties is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_properties(self.ptr)
            self._properties = Properties.from_ptr(ptr)
        return self._properties

    @property
    def required_use(self):
        """Get a package's REQUIRED_USE."""
        if self._required_use is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_required_use(self.ptr)
            self._required_use = RequiredUse.from_ptr(ptr)
        return self._required_use

    @property
    def restrict(self):
        """Get a package's RESTRICT."""
        if self._restrict is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_restrict(self.ptr)
            self._restrict = Restrict.from_ptr(ptr)
        return self._restrict

    @property
    def src_uri(self):
        """Get a package's SRC_URI."""
        if self._src_uri is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_src_uri(self.ptr)
            self._src_uri = SrcUri.from_ptr(ptr)
        return self._src_uri

    @property
    def defined_phases(self):
        """Get a package's defined phases."""
        cdef size_t length
        if self._defined_phases is None:
            phases = C.pkgcraft_pkg_ebuild_defined_phases(self.ptr, &length)
            self._defined_phases = OrderedFrozenSet(phases[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(phases, length)
        return self._defined_phases

    @property
    def homepage(self):
        """Get a package's homepage."""
        cdef size_t length
        if self._homepage is None:
            uris = C.pkgcraft_pkg_ebuild_homepage(self.ptr, &length)
            self._homepage = OrderedFrozenSet(uris[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(uris, length)
        return self._homepage

    @property
    def keywords(self):
        """Get a package's keywords."""
        cdef size_t length
        if self._keywords is None:
            keywords = C.pkgcraft_pkg_ebuild_keywords(self.ptr, &length)
            self._keywords = OrderedFrozenSet(keywords[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(keywords, length)
        return self._keywords

    @property
    def iuse(self):
        """Get a package's USE flags."""
        cdef size_t length
        if self._iuse is None:
            iuse = C.pkgcraft_pkg_ebuild_iuse(self.ptr, &length)
            self._iuse = OrderedFrozenSet(iuse[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(iuse, length)
        return self._iuse

    @property
    def inherit(self):
        """Get a package's ordered set of directly inherited eclasses."""
        cdef size_t length
        if self._inherit is None:
            eclasses = C.pkgcraft_pkg_ebuild_inherit(self.ptr, &length)
            self._inherit = OrderedFrozenSet(eclasses[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(eclasses, length)
        return self._inherit

    @property
    def inherited(self):
        """Get a package's ordered set of inherited eclasses."""
        cdef size_t length
        if self._inherited is None:
            eclasses = C.pkgcraft_pkg_ebuild_inherited(self.ptr, &length)
            self._inherited = OrderedFrozenSet(eclasses[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(eclasses, length)
        return self._inherited

    @property
    def long_description(self):
        """Get a package's long description."""
        return ptr_to_str(C.pkgcraft_pkg_ebuild_long_description(self.ptr))

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
            ptr = C.pkgcraft_pkg_ebuild_upstream(self.ptr)
            self._upstream = Upstream.from_ptr(ptr)
        return self._upstream


@cython.final
cdef class Maintainer:
    """Ebuild package maintainer."""

    def __cinit__(self, str email not None, str name=None, str description=None,
                  str maint_type=None, str proxied=None):
        self.email = email
        self.name = name
        self.description = description
        self.maint_type = maint_type
        self.proxied = proxied

    @staticmethod
    cdef Maintainer from_ptr(C.Maintainer *m):
        """Create a Maintainer from a pointer."""
        return Maintainer(
            m.email.decode(),
            name=ptr_to_str(m.name, free=False),
            description=ptr_to_str(m.description, free=False),
            maint_type=ptr_to_str(m.maint_type, free=False),
            proxied=ptr_to_str(m.proxied, free=False),
        )

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
cdef class RemoteId:
    """Ebuild package upstream site."""

    @staticmethod
    cdef RemoteId from_ptr(C.RemoteId *r):
        """Create an RemoteId from a pointer."""
        obj = <RemoteId>RemoteId.__new__(RemoteId)
        obj.site = r.site.decode()
        obj.name = r.name.decode()
        return obj

    def __str__(self):
        return f'{self.site}: {self.name}'

    def __repr__(self):
        name = self.__class__.__name__
        return f"<{name} '{self}'>"


@cython.final
cdef class UpstreamMaintainer:
    """Upstream package maintainer."""

    @staticmethod
    cdef UpstreamMaintainer from_ptr(C.UpstreamMaintainer *m):
        """Create an UpstreamMaintainer from a pointer."""
        obj = <UpstreamMaintainer>UpstreamMaintainer.__new__(UpstreamMaintainer)
        obj.name = m.name.decode()
        obj.email = ptr_to_str(m.email, free=False)
        obj.status = m.status.decode()
        return obj

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
cdef class Upstream:
    """Ebuild package upstream info."""

    @staticmethod
    cdef Upstream from_ptr(C.Upstream *u):
        """Create an Upstream from a pointer."""
        obj = None

        if u is not NULL:
            obj = <Upstream>Upstream.__new__(Upstream)
            obj.remote_ids = tuple(
                RemoteId.from_ptr(u.remote_ids[i]) for i in range(u.remote_ids_len))
            obj.maintainers = tuple(
                UpstreamMaintainer.from_ptr(u.maintainers[i]) for i in range(u.maintainers_len))
            obj.bugs_to = ptr_to_str(u.bugs_to, free=False)
            obj.changelog = ptr_to_str(u.changelog, free=False)
            obj.doc = ptr_to_str(u.doc, free=False)
            C.pkgcraft_pkg_ebuild_upstream_free(u)

        return obj
