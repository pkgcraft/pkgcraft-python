from .. cimport pkgcraft_c as C
from .._misc cimport SENTINEL
from ..depset cimport DepSet
from . cimport Pkg
from ..error import PkgcraftError
from ..repo cimport EbuildRepo


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
    def repo(self):
        """Get a package's repo."""
        cdef const C.Repo *repo = C.pkgcraft_pkg_repo(self._pkg)
        return EbuildRepo.from_ptr(repo, True)

    @property
    def path(self):
        """Get a package's path."""
        cdef char *c_str = C.pkgcraft_ebuild_pkg_path(self._ebuild_pkg)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    @property
    def ebuild(self):
        """Get a package's ebuild file content."""
        cdef char *c_str = C.pkgcraft_ebuild_pkg_ebuild(self._ebuild_pkg)
        if c_str is NULL:
            raise PkgcraftError
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    @property
    def description(self):
        """Get a package's description."""
        cdef char *c_str
        if self._description is None:
            c_str = C.pkgcraft_ebuild_pkg_description(self._ebuild_pkg)
            self._description = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._description

    @property
    def slot(self):
        """Get a package's slot."""
        cdef char *c_str
        if self._slot is None:
            c_str = C.pkgcraft_ebuild_pkg_slot(self._ebuild_pkg)
            self._slot = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._slot

    @property
    def subslot(self):
        """Get a package's subslot."""
        cdef char *c_str
        if self._subslot is None:
            c_str = C.pkgcraft_ebuild_pkg_subslot(self._ebuild_pkg)
            self._subslot = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._subslot

    @property
    def depend(self):
        """Get a package's DEPEND."""
        cdef C.DepSet *deps
        if self._depend is SENTINEL:
            deps = C.pkgcraft_ebuild_pkg_depend(self._ebuild_pkg)
            self._depend = None if deps is NULL else DepSet.from_ptr(deps)
        return self._depend

    @property
    def bdepend(self):
        """Get a package's BDEPEND."""
        cdef C.DepSet *deps
        if self._bdepend is SENTINEL:
            deps = C.pkgcraft_ebuild_pkg_bdepend(self._ebuild_pkg)
            self._bdepend = None if deps is NULL else DepSet.from_ptr(deps)
        return self._bdepend

    @property
    def idepend(self):
        """Get a package's IDEPEND."""
        cdef C.DepSet *deps
        if self._idepend is SENTINEL:
            deps = C.pkgcraft_ebuild_pkg_idepend(self._ebuild_pkg)
            self._idepend = None if deps is NULL else DepSet.from_ptr(deps)
        return self._idepend

    @property
    def pdepend(self):
        """Get a package's PDEPEND."""
        cdef C.DepSet *deps
        if self._pdepend is SENTINEL:
            deps = C.pkgcraft_ebuild_pkg_pdepend(self._ebuild_pkg)
            self._pdepend = None if deps is NULL else DepSet.from_ptr(deps)
        return self._pdepend

    @property
    def rdepend(self):
        """Get a package's RDEPEND."""
        cdef C.DepSet *deps
        if self._rdepend is SENTINEL:
            deps = C.pkgcraft_ebuild_pkg_rdepend(self._ebuild_pkg)
            self._rdepend = None if deps is NULL else DepSet.from_ptr(deps)
        return self._rdepend

    @property
    def license(self):
        """Get a package's LICENSE."""
        cdef C.DepSet *deps
        if self._license is SENTINEL:
            deps = C.pkgcraft_ebuild_pkg_license(self._ebuild_pkg)
            self._license = None if deps is NULL else DepSet.from_ptr(deps)
        return self._license

    @property
    def properties(self):
        """Get a package's PROPERTIES."""
        cdef C.DepSet *deps
        if self._properties is SENTINEL:
            deps = C.pkgcraft_ebuild_pkg_properties(self._ebuild_pkg)
            self._properties = None if deps is NULL else DepSet.from_ptr(deps)
        return self._properties

    @property
    def required_use(self):
        """Get a package's REQUIRED_USE."""
        cdef C.DepSet *deps
        if self._required_use is SENTINEL:
            deps = C.pkgcraft_ebuild_pkg_required_use(self._ebuild_pkg)
            self._required_use = None if deps is NULL else DepSet.from_ptr(deps)
        return self._required_use

    @property
    def restrict(self):
        """Get a package's RESTRICT."""
        cdef C.DepSet *deps
        if self._restrict is SENTINEL:
            deps = C.pkgcraft_ebuild_pkg_restrict(self._ebuild_pkg)
            self._restrict = None if deps is NULL else DepSet.from_ptr(deps)
        return self._restrict

    @property
    def src_uri(self):
        """Get a package's SRC_URI."""
        cdef C.DepSet *deps
        if self._src_uri is SENTINEL:
            deps = C.pkgcraft_ebuild_pkg_src_uri(self._ebuild_pkg)
            self._src_uri = None if deps is NULL else DepSet.from_ptr(deps)
        return self._src_uri

    @property
    def defined_phases(self):
        """Get a package's defined phases."""
        cdef char **phases
        cdef size_t length

        if self._defined_phases is None:
            phases = C.pkgcraft_ebuild_pkg_defined_phases(self._ebuild_pkg, &length)
            self._defined_phases = frozenset(phases[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(phases, length)
        return self._defined_phases

    @property
    def homepage(self):
        """Get a package's homepage."""
        cdef char **uris
        cdef size_t length

        if self._homepage is None:
            uris = C.pkgcraft_ebuild_pkg_homepage(self._ebuild_pkg, &length)
            self._homepage = tuple(uris[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(uris, length)
        return self._homepage

    @property
    def keywords(self):
        """Get a package's keywords."""
        cdef char **keywords
        cdef size_t length

        if self._keywords is None:
            keywords = C.pkgcraft_ebuild_pkg_keywords(self._ebuild_pkg, &length)
            self._keywords = tuple(keywords[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(keywords, length)
        return self._keywords

    @property
    def iuse(self):
        """Get a package's USE flags."""
        cdef char **iuse
        cdef size_t length

        if self._iuse is None:
            iuse = C.pkgcraft_ebuild_pkg_iuse(self._ebuild_pkg, &length)
            self._iuse = frozenset(iuse[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(iuse, length)
        return self._iuse

    @property
    def inherit(self):
        """Get a package's ordered set of directly inherited eclasses."""
        cdef char **eclasses
        cdef size_t length

        if self._inherit is None:
            eclasses = C.pkgcraft_ebuild_pkg_inherit(self._ebuild_pkg, &length)
            self._inherit = tuple(eclasses[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(eclasses, length)
        return self._inherit

    @property
    def inherited(self):
        """Get a package's ordered set of inherited eclasses."""
        cdef char **eclasses
        cdef size_t length

        if self._inherited is None:
            eclasses = C.pkgcraft_ebuild_pkg_inherited(self._ebuild_pkg, &length)
            self._inherited = tuple(eclasses[i].decode() for i in range(length))
            C.pkgcraft_str_array_free(eclasses, length)
        return self._inherited

    @property
    def long_description(self):
        """Get a package's long description."""
        cdef char *c_str
        c_str = C.pkgcraft_ebuild_pkg_long_description(self._ebuild_pkg)
        if c_str is NULL:
            return None
        else:
            long_desc = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return long_desc

    @property
    def maintainers(self):
        """Get a package's maintainers."""
        cdef C.Maintainer **maintainers
        cdef size_t length

        if self._maintainers is None:
            maintainers = C.pkgcraft_ebuild_pkg_maintainers(self._ebuild_pkg, &length)
            self._maintainers = tuple(Maintainer.create(maintainers[i][0]) for i in range(length))
            C.pkgcraft_ebuild_pkg_maintainers_free(maintainers, length)
        return self._maintainers

    @property
    def upstreams(self):
        """Get a package's upstreams."""
        cdef C.Upstream **upstreams
        cdef size_t length

        if self._upstreams is None:
            upstreams = C.pkgcraft_ebuild_pkg_upstreams(self._ebuild_pkg, &length)
            self._upstreams = tuple(Upstream.create(upstreams[i][0]) for i in range(length))
            C.pkgcraft_ebuild_pkg_upstreams_free(upstreams, length)
        return self._upstreams


cdef class Maintainer:
    """Ebuild package maintainer."""

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


cdef class Upstream:
    """Ebuild package upstream."""

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
