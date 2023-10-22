cimport cython

from .. cimport C
from .._misc cimport CStringArray, cstring_to_str
from ..error cimport _IndirectInit
from .set cimport _IntoIter, _IntoIterFlatten, _IntoIterRecursive
from ..types import OrderedFrozenSet


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

    def evaluate(self, enabled=()):
        """Evaluate a DepSpec using a given set of enabled options or by force."""
        cdef size_t length

        if isinstance(enabled, bool):
            # forcible evaluation, enabling or disabling all conditionals
            ptrs = C.pkgcraft_dep_spec_evaluate_force(self.ptr, enabled, &length)
        else:
            # use options to determine conditionals
            opts = CStringArray(enabled)
            ptrs = C.pkgcraft_dep_spec_evaluate(self.ptr, opts.ptr, len(opts), &length)

        deps = OrderedFrozenSet(DepSpec.from_ptr(ptrs[i]) for i in range(length))
        C.pkgcraft_array_free(<void **>ptrs, length)
        return deps

    def iter_flatten(self):
        """Iterate over the objects of a flattened DepSpec."""
        yield from _IntoIterFlatten(self)

    def iter_recursive(self):
        """Recursively iterate over the DepSpec objects of a DepSpec."""
        yield from _IntoIterRecursive(self)

    def __contains__(self, obj):
        if isinstance(obj, DepSpec):
            return C.pkgcraft_dep_spec_contains(self.ptr, (<DepSpec>obj).ptr)
        return False

    def __iter__(self):
        return _IntoIter(self)

    def __len__(self):
        return C.pkgcraft_dep_spec_len(self.ptr)

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
