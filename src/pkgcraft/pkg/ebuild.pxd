from .. cimport pkgcraft_c as C
from . cimport Pkg

cdef class EbuildPkg(Pkg):
    cdef C.EbuildPkg *_ebuild_pkg
    # cached fields
    cdef str _description
    cdef str _slot
    cdef str _subslot
    cdef object _depend
    cdef object _bdepend
    cdef object _idepend
    cdef object _pdepend
    cdef object _rdepend
    cdef object _license
    cdef object _properties
    cdef object _required_use
    cdef object _restrict
    cdef object _src_uri
    cdef frozenset _defined_phases
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
