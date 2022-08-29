from .. cimport pkgcraft_c as C
from . cimport Pkg
from ..error import PkgcraftError
from ..repo cimport EbuildRepo


cdef class EbuildPkg(Pkg):
    """Generic ebuild package."""

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
