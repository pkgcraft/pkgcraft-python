cimport cython

from .. cimport C
from .._misc cimport cstring_to_str
from ..error cimport _IndirectInit
from .set cimport _IntoIterFlatten, _IntoIterRecursive


@cython.final
cdef class DepSpec(_IndirectInit):
    """Dependency object."""

    @staticmethod
    cdef DepSpec from_ptr(C.DepSpec *ptr):
        """Create a DepSpec from a pointer and type."""
        if ptr.kind == C.DEP_SPEC_KIND_ENABLED:
            obj = <Enabled>Enabled.__new__(Enabled)
        elif ptr.kind == C.DEP_SPEC_KIND_DISABLED:
            obj = <Disabled>Disabled.__new__(Disabled)
        elif ptr.kind == C.DEP_SPEC_KIND_ALL_OF:
            obj = <AllOf>AllOf.__new__(AllOf)
        elif ptr.kind == C.DEP_SPEC_KIND_ANY_OF:
            obj = <AnyOf>AnyOf.__new__(AnyOf)
        elif ptr.kind == C.DEP_SPEC_KIND_EXACTLY_ONE_OF:
            obj = <ExactlyOneOf>ExactlyOneOf.__new__(ExactlyOneOf)
        elif ptr.kind == C.DEP_SPEC_KIND_AT_MOST_ONE_OF:
            obj = <AtMostOneOf>AtMostOneOf.__new__(AtMostOneOf)
        elif ptr.kind == C.DEP_SPEC_KIND_USE_ENABLED:
            obj = <UseEnabled>UseEnabled.__new__(UseEnabled)
        elif ptr.kind == C.DEP_SPEC_KIND_USE_DISABLED:
            obj = <UseDisabled>UseDisabled.__new__(UseDisabled)
        else:  # pragma: no cover
            raise TypeError(f'unknown DepSpec kind: {ptr.kind}')

        obj.ptr = ptr
        return obj

    def iter_flatten(self):
        """Iterate over the objects of a flattened DepSpec."""
        yield from _IntoIterFlatten(self)

    def iter_recursive(self):
        """Recursively iterate over the DepSpec objects of a DepSpec."""
        yield from _IntoIterRecursive(self)

    def __lt__(self, other):
        if isinstance(other, DepSpec):
            return C.pkgcraft_dep_spec_cmp(self.ptr, (<DepSpec>other).ptr) == -1
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, DepSpec):
            return C.pkgcraft_dep_spec_cmp(self.ptr, (<DepSpec>other).ptr) <= 0
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, DepSpec):
            return C.pkgcraft_dep_spec_cmp(self.ptr, (<DepSpec>other).ptr) == 0
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, DepSpec):
            return C.pkgcraft_dep_spec_cmp(self.ptr, (<DepSpec>other).ptr) != 0
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, DepSpec):
            return C.pkgcraft_dep_spec_cmp(self.ptr, (<DepSpec>other).ptr) >= 0
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, DepSpec):
            return C.pkgcraft_dep_spec_cmp(self.ptr, (<DepSpec>other).ptr) == 1
        return NotImplemented

    def __hash__(self):
        return C.pkgcraft_dep_spec_hash(self.ptr)

    def __str__(self):
        return cstring_to_str(C.pkgcraft_dep_spec_str(self.ptr))

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __dealloc__(self):
        C.pkgcraft_dep_spec_free(self.ptr)
