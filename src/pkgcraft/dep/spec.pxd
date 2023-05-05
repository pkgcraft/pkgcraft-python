from .. cimport C
from ..error cimport _IndirectInit


cdef class DepSpec(_IndirectInit):
    cdef C.DepSpec *ptr

    @staticmethod
    cdef DepSpec from_ptr(C.DepSpec *)


cdef class Enabled(DepSpec):
    """Enabled dependency."""


cdef class Disabled(DepSpec):
    """Disabled dependency."""


cdef class AllOf(DepSpec):
    """All of a given dependency set."""


cdef class AnyOf(DepSpec):
    """Any of a given dependency set."""


cdef class ExactlyOneOf(DepSpec):
    """Exactly one of a given dependency set."""


cdef class AtMostOneOf(DepSpec):
    """At most one of a given dependency set."""


cdef class UseDisabled(DepSpec):
    """Conditionally disabled dependency."""


cdef class UseEnabled(DepSpec):
    """Conditionally enabled dependency."""
