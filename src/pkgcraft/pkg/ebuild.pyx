from pathlib import Path

cimport cython

from .. cimport pkgcraft_c as C
from .._misc cimport SENTINEL
from ..depset cimport DepSet, DepSetAtom, DepSetString, DepSetUri
from . cimport Pkg

from ..error import IndirectInit, PkgcraftError
from ..set import OrderedFrozenSet


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

    @property
    def path(self):
        """Get a package's path."""
        c_str = C.pkgcraft_pkg_ebuild_path(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return Path(s)

    @property
    def ebuild(self):
        """Get a package's ebuild file content."""
        c_str = C.pkgcraft_pkg_ebuild_ebuild(self.ptr)
        if c_str is NULL:
            raise PkgcraftError
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    @property
    def description(self):
        """Get a package's description."""
        if self._description is None:
            c_str = C.pkgcraft_pkg_ebuild_description(self.ptr)
            self._description = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._description

    @property
    def slot(self):
        """Get a package's slot."""
        if self._slot is None:
            c_str = C.pkgcraft_pkg_ebuild_slot(self.ptr)
            self._slot = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._slot

    @property
    def subslot(self):
        """Get a package's subslot."""
        if self._subslot is None:
            c_str = C.pkgcraft_pkg_ebuild_subslot(self.ptr)
            self._subslot = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._subslot

    @property
    def depend(self):
        """Get a package's DEPEND."""
        if self._depend is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_depend(self.ptr)
            self._depend = None if ptr is NULL else DepSet.from_ptr(ptr, DepSetAtom)
        return self._depend

    @property
    def bdepend(self):
        """Get a package's BDEPEND."""
        if self._bdepend is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_bdepend(self.ptr)
            self._bdepend = None if ptr is NULL else DepSet.from_ptr(ptr, DepSetAtom)
        return self._bdepend

    @property
    def idepend(self):
        """Get a package's IDEPEND."""
        if self._idepend is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_idepend(self.ptr)
            self._idepend = None if ptr is NULL else DepSet.from_ptr(ptr, DepSetAtom)
        return self._idepend

    @property
    def pdepend(self):
        """Get a package's PDEPEND."""
        if self._pdepend is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_pdepend(self.ptr)
            self._pdepend = None if ptr is NULL else DepSet.from_ptr(ptr, DepSetAtom)
        return self._pdepend

    @property
    def rdepend(self):
        """Get a package's RDEPEND."""
        if self._rdepend is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_rdepend(self.ptr)
            self._rdepend = None if ptr is NULL else DepSet.from_ptr(ptr, DepSetAtom)
        return self._rdepend

    @property
    def license(self):
        """Get a package's LICENSE."""
        if self._license is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_license(self.ptr)
            self._license = None if ptr is NULL else DepSet.from_ptr(ptr, DepSetString)
        return self._license

    @property
    def properties(self):
        """Get a package's PROPERTIES."""
        if self._properties is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_properties(self.ptr)
            self._properties = None if ptr is NULL else DepSet.from_ptr(ptr, DepSetString)
        return self._properties

    @property
    def required_use(self):
        """Get a package's REQUIRED_USE."""
        if self._required_use is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_required_use(self.ptr)
            self._required_use = None if ptr is NULL else DepSet.from_ptr(ptr, DepSetString)
        return self._required_use

    @property
    def restrict(self):
        """Get a package's RESTRICT."""
        if self._restrict is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_restrict(self.ptr)
            self._restrict = None if ptr is NULL else DepSet.from_ptr(ptr, DepSetString)
        return self._restrict

    @property
    def src_uri(self):
        """Get a package's SRC_URI."""
        if self._src_uri is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_src_uri(self.ptr)
            self._src_uri = None if ptr is NULL else DepSet.from_ptr(ptr, DepSetUri)
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
        c_str = C.pkgcraft_pkg_ebuild_long_description(self.ptr)
        if c_str is NULL:
            return None
        else:
            long_desc = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return long_desc

    @property
    def maintainers(self):
        """Get a package's maintainers."""
        cdef size_t length
        if self._maintainers is None:
            maintainers = C.pkgcraft_pkg_ebuild_maintainers(self.ptr, &length)
            data = (Maintainer.create(maintainers[i][0]) for i in range(length))
            self._maintainers = OrderedFrozenSet(data)
            C.pkgcraft_pkg_ebuild_maintainers_free(maintainers, length)
        return self._maintainers

    @property
    def upstreams(self):
        """Get a package's upstreams."""
        cdef size_t length
        if self._upstreams is None:
            upstreams = C.pkgcraft_pkg_ebuild_upstreams(self.ptr, &length)
            data = (Upstream.create(upstreams[i][0]) for i in range(length))
            self._upstreams = OrderedFrozenSet(data)
            C.pkgcraft_pkg_ebuild_upstreams_free(upstreams, length)
        return self._upstreams


@cython.final
cdef class Maintainer:
    """Ebuild package maintainer."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    @staticmethod
    cdef Maintainer create(C.Maintainer m):
        obj = <Maintainer>Maintainer.__new__(Maintainer)
        obj.email = m.email.decode()
        obj.name = m.name.decode() if m.name is not NULL else None
        obj.description = m.description.decode() if m.description is not NULL else None
        obj.maint_type = m.maint_type.decode() if m.maint_type is not NULL else None
        obj.proxied = m.proxied.decode() if m.proxied is not NULL else None
        return obj

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
cdef class Upstream:
    """Ebuild package upstream."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    @staticmethod
    cdef Upstream create(C.Upstream u):
        obj = <Upstream>Upstream.__new__(Upstream)
        obj.site = u.site.decode()
        obj.name = u.name.decode()
        return obj

    def __str__(self):
        return f'{self.site}: {self.name}'

    def __repr__(self):
        name = self.__class__.__name__
        return f"<{name} '{self}'>"

    def __hash__(self):
        return hash((self.site, self.name))
