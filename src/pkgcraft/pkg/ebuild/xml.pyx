cimport cython

from ... cimport C
from ..._misc cimport cstring_to_str
from ...error cimport Indirect


@cython.final
cdef class Maintainer(Indirect):
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
cdef class RemoteId(Indirect):
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
cdef class UpstreamMaintainer(Indirect):
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
cdef class Upstream(Indirect):
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



