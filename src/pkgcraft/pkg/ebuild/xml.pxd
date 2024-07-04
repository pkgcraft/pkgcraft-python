from ... cimport C
from ...error cimport Indirect


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


