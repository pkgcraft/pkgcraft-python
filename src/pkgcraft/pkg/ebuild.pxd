from .. cimport C
from ..dep cimport DepSet
from ..error cimport _IndirectInit
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
    cdef object _defined_phases
    cdef object _homepage
    cdef object _keywords
    cdef object _inherit
    cdef object _inherited
    cdef object _maintainers
    cdef object _upstream
    cdef object _iuse


cdef class Maintainer(_IndirectInit):
    cdef readonly str email
    cdef readonly str name
    cdef readonly str description
    cdef readonly str maint_type
    cdef readonly str proxied

    @staticmethod
    cdef Maintainer from_ptr(C.Maintainer *)


cdef class RemoteId(_IndirectInit):
    cdef readonly str site
    cdef readonly str name

    @staticmethod
    cdef RemoteId from_ptr(C.RemoteId *)


cdef class UpstreamMaintainer(_IndirectInit):
    cdef readonly str name
    cdef readonly str email
    cdef readonly str status

    @staticmethod
    cdef UpstreamMaintainer from_ptr(C.UpstreamMaintainer *)


cdef class Upstream(_IndirectInit):
    cdef readonly tuple remote_ids
    cdef readonly tuple maintainers
    cdef readonly str bugs_to
    cdef readonly str changelog
    cdef readonly str doc

    @staticmethod
    cdef Upstream from_ptr(C.Upstream *)
