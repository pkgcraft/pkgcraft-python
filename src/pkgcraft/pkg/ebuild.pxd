from .. cimport C
from ..dep cimport DepSet
from ..error cimport Indirect
from ..types cimport OrderedFrozenSet
from . cimport Pkg


cdef class EbuildPkg(Pkg):
    # cached fields
    cdef str _description
    cdef str _slot
    cdef str _subslot
    cdef DepSet _depend
    cdef DepSet _bdepend
    cdef DepSet _idepend
    cdef DepSet _pdepend
    cdef DepSet _rdepend
    cdef DepSet _license
    cdef DepSet _properties
    cdef DepSet _required_use
    cdef DepSet _restrict
    cdef DepSet _src_uri
    cdef OrderedFrozenSet _defined_phases
    cdef OrderedFrozenSet _homepage
    cdef OrderedFrozenSet _keywords
    cdef OrderedFrozenSet _inherit
    cdef OrderedFrozenSet _inherited
    cdef OrderedFrozenSet _iuse
    cdef OrderedFrozenSet _maintainers
    cdef object _upstream


cdef class Maintainer(Indirect):
    cdef readonly str email
    cdef readonly str name
    cdef readonly str description
    cdef readonly str maint_type
    cdef readonly str proxied

    @staticmethod
    cdef Maintainer from_ptr(C.Maintainer *)


cdef class RemoteId(Indirect):
    cdef readonly str site
    cdef readonly str name

    @staticmethod
    cdef RemoteId from_ptr(C.RemoteId *)


cdef class UpstreamMaintainer(Indirect):
    cdef readonly str name
    cdef readonly str email
    cdef readonly str status

    @staticmethod
    cdef UpstreamMaintainer from_ptr(C.UpstreamMaintainer *)


cdef class Upstream(Indirect):
    cdef readonly tuple remote_ids
    cdef readonly tuple maintainers
    cdef readonly str bugs_to
    cdef readonly str changelog
    cdef readonly str doc

    @staticmethod
    cdef Upstream from_ptr(C.Upstream *)


cdef class ConfiguredPkg(EbuildPkg):
    pass
