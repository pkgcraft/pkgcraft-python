from pathlib import Path

cimport cython
from cpython.mem cimport PyMem_Free, PyMem_Malloc

from .. cimport pkgcraft_c as C
from .._misc cimport SENTINEL
from ..depset cimport DepSet, DepSetAtom, DepSetString, DepSetUri
from . cimport Pkg

from ..error import PkgcraftError
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

    def dependencies(self, *keys):
        """Get a package's dependencies for the given descriptors.

        Returns a DepSet encompassing all dependencies when no descriptors are passed.
        """
        array = <char **> PyMem_Malloc(len(keys) * sizeof(char *))
        if not array:  # pragma: no cover
            raise MemoryError
        for (i, s) in enumerate(keys):
            key_bytes = (<str?>s.upper()).encode()
            array[i] = key_bytes
        ptr = C.pkgcraft_pkg_ebuild_dependencies(self.ptr, array, len(keys))
        if ptr is NULL:
            raise PkgcraftError
        deps = DepSet.from_ptr(ptr, DepSetAtom)
        PyMem_Free(array)
        return deps

    @property
    def bdepend(self):
        """Get a package's BDEPEND."""
        if self._bdepend is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_bdepend(self.ptr)
            self._bdepend = DepSet.from_ptr(ptr, DepSetAtom)
        return self._bdepend

    @property
    def depend(self):
        """Get a package's DEPEND."""
        if self._depend is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_depend(self.ptr)
            self._depend = DepSet.from_ptr(ptr, DepSetAtom)
        return self._depend

    @property
    def idepend(self):
        """Get a package's IDEPEND."""
        if self._idepend is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_idepend(self.ptr)
            self._idepend = DepSet.from_ptr(ptr, DepSetAtom)
        return self._idepend

    @property
    def pdepend(self):
        """Get a package's PDEPEND."""
        if self._pdepend is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_pdepend(self.ptr)
            self._pdepend = DepSet.from_ptr(ptr, DepSetAtom)
        return self._pdepend

    @property
    def rdepend(self):
        """Get a package's RDEPEND."""
        if self._rdepend is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_rdepend(self.ptr)
            self._rdepend = DepSet.from_ptr(ptr, DepSetAtom)
        return self._rdepend

    @property
    def license(self):
        """Get a package's LICENSE."""
        if self._license is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_license(self.ptr)
            self._license = DepSet.from_ptr(ptr, DepSetString)
        return self._license

    @property
    def properties(self):
        """Get a package's PROPERTIES."""
        if self._properties is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_properties(self.ptr)
            self._properties = DepSet.from_ptr(ptr, DepSetString)
        return self._properties

    @property
    def required_use(self):
        """Get a package's REQUIRED_USE."""
        if self._required_use is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_required_use(self.ptr)
            self._required_use = DepSet.from_ptr(ptr, DepSetString)
        return self._required_use

    @property
    def restrict(self):
        """Get a package's RESTRICT."""
        if self._restrict is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_restrict(self.ptr)
            self._restrict = DepSet.from_ptr(ptr, DepSetString)
        return self._restrict

    @property
    def src_uri(self):
        """Get a package's SRC_URI."""
        if self._src_uri is SENTINEL:
            ptr = C.pkgcraft_pkg_ebuild_src_uri(self.ptr)
            self._src_uri = DepSet.from_ptr(ptr, DepSetUri)
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

    def __cinit__(self, str email not None, str name=None, str description=None,
                  str maint_type=None, str proxied=None):
        self.email = email
        self.name = name
        self.description = description
        self.maint_type = maint_type
        self.proxied = proxied

    @staticmethod
    cdef Maintainer create(C.Maintainer m):
        return Maintainer(
            m.email.decode(),
            name=m.name.decode() if m.name is not NULL else None,
            description=m.description.decode() if m.description is not NULL else None,
            maint_type=m.maint_type.decode() if m.maint_type is not NULL else None,
            proxied=m.proxied.decode() if m.proxied is not NULL else None,
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
cdef class Upstream:
    """Ebuild package upstream."""

    def __cinit__(self, str site not None, str name not None):
        self.site = site
        self.name = name

    @staticmethod
    cdef Upstream create(C.Upstream u):
        return Upstream(u.site.decode(), u.name.decode())

    def __str__(self):
        return f'{self.site}: {self.name}'

    def __repr__(self):
        name = self.__class__.__name__
        return f"<{name} '{self}'>"

    def __hash__(self):
        return hash((self.site, self.name))
