from .. cimport C
from ..error cimport _IndirectInit
from . cimport Pkg


cdef class EbuildPkg(Pkg):
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
