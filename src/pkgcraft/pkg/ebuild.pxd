from .. cimport pkgcraft_c as C
from . cimport Pkg

cdef class EbuildPkg(Pkg):
    cdef C.EbuildPkg *_ebuild_pkg
    # cached fields
    cdef str _description
    cdef str _slot
    cdef str _subslot
    cdef tuple _homepage
    cdef tuple _keywords
    cdef tuple _inherit
    cdef tuple _inherited
    cdef tuple _maintainers
    cdef tuple _upstreams
    cdef frozenset _iuse


cdef class Maintainer:
    cdef readonly str email
    cdef readonly str name
    cdef readonly str description
    cdef readonly str maint_type
    cdef readonly str proxied

    @staticmethod
    cdef Maintainer create(C.Maintainer)


cdef class Upstream:
    cdef readonly str site
    cdef readonly str name

    @staticmethod
    cdef Upstream create(C.Upstream)
