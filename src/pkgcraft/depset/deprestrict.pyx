cimport cython

from .. cimport pkgcraft_c as C
from ..error cimport _IndirectInit
from .base cimport _IntoIterFlatten, _IntoIterRecursive


@cython.final
cdef class DepRestrict(_IndirectInit):
    """Dependency restriction."""

    @staticmethod
    cdef DepRestrict from_ptr(C.DepRestrict *ptr):
        """Create a DepRestrict from a pointer and type."""
        kind = ptr.kind_dep
        if kind == C.DEP_KIND_ENABLED:
            obj = <Enabled>Enabled.__new__(Enabled)
        elif kind == C.DEP_KIND_DISABLED:
            obj = <Disabled>Disabled.__new__(Disabled)
        elif kind == C.DEP_KIND_ALL_OF:
            obj = <AllOf>AllOf.__new__(AllOf)
        elif kind == C.DEP_KIND_ANY_OF:
            obj = <AnyOf>AnyOf.__new__(AnyOf)
        elif kind == C.DEP_KIND_EXACTLY_ONE_OF:
            obj = <ExactlyOneOf>ExactlyOneOf.__new__(ExactlyOneOf)
        elif kind == C.DEP_KIND_AT_MOST_ONE_OF:
            obj = <AtMostOneOf>AtMostOneOf.__new__(AtMostOneOf)
        elif kind == C.DEP_KIND_USE_ENABLED:
            obj = <UseEnabled>UseEnabled.__new__(UseEnabled)
        elif kind == C.DEP_KIND_USE_DISABLED:
            obj = <UseDisabled>UseDisabled.__new__(UseDisabled)
        else:  # pragma: no cover
            raise TypeError(f'unknown DepRestrict kind: {kind}')

        obj.ptr = ptr
        obj.kind = ptr.kind
        return obj

    def iter_flatten(self):
        yield from _IntoIterFlatten(self)

    def iter_recursive(self):
        """Recursively iterate over all DepRestrict objects of a DepRestrict."""
        yield from _IntoIterRecursive(self)

    def __lt__(self, other):
        if isinstance(other, DepRestrict):
            return C.pkgcraft_deprestrict_cmp(self.ptr, (<DepRestrict>other).ptr) == -1
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, DepRestrict):
            return C.pkgcraft_deprestrict_cmp(self.ptr, (<DepRestrict>other).ptr) <= 0
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, DepRestrict):
            return C.pkgcraft_deprestrict_cmp(self.ptr, (<DepRestrict>other).ptr) == 0
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, DepRestrict):
            return C.pkgcraft_deprestrict_cmp(self.ptr, (<DepRestrict>other).ptr) != 0
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, DepRestrict):
            return C.pkgcraft_deprestrict_cmp(self.ptr, (<DepRestrict>other).ptr) >= 0
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, DepRestrict):
            return C.pkgcraft_deprestrict_cmp(self.ptr, (<DepRestrict>other).ptr) == 1
        return NotImplemented

    def __hash__(self):
        return C.pkgcraft_deprestrict_hash(self.ptr)

    def __str__(self):
        c_str = C.pkgcraft_deprestrict_str(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __dealloc__(self):
        C.pkgcraft_deprestrict_free(self.ptr)
