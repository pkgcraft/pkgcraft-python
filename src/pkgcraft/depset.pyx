cimport cython

from . cimport pkgcraft_c as C
from .atom cimport Atom
from .error cimport _IndirectInit


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


@cython.final
cdef class DepSet(_IndirectInit):
    """Dependency set of objects."""

    @staticmethod
    cdef DepSet from_ptr(C.DepSet *ptr):
        if ptr is not NULL:
            obj = <DepSet>DepSet.__new__(DepSet)
            obj.ptr = ptr
            obj.kind = ptr.kind
            return obj
        return None

    def iter_flatten(self):
        """Iterate over the objects of a flattened DepSet."""
        yield from _IntoIterFlatten(self)

    def iter_recursive(self):
        """Recursively iterate over all DepRestrict objects of a DepSet."""
        yield from _IntoIterRecursive(self)

    def __iter__(self):
        return _IntoIter(self)

    def __eq__(self, other):
        if isinstance(other, DepSet):
            return C.pkgcraft_depset_eq(self.ptr, (<DepSet>other).ptr)
        return NotImplemented

    def __hash__(self):
        return C.pkgcraft_depset_hash(self.ptr)

    def __str__(self):
        c_str = C.pkgcraft_depset_str(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __dealloc__(self):
        C.pkgcraft_depset_free(self.ptr)


cdef class _IntoIter:
    """Iterator over a DepSet."""

    def __cinit__(self, DepSet d not None):
        self.ptr = C.pkgcraft_depset_into_iter(d.ptr)
        self.kind = d.kind

    def __iter__(self):
        return self

    def __next__(self):
        ptr = C.pkgcraft_depset_into_iter_next(self.ptr)
        if ptr is not NULL:
            return DepRestrict.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_depset_into_iter_free(self.ptr)


cdef class _IntoIterFlatten:
    """Flattened iterator over a DepSet or DepRestrict object."""

    def __cinit__(self, object obj not None):
        if isinstance(obj, DepSet):
            deps = <DepSet>obj
            self.ptr = C.pkgcraft_depset_into_iter_flatten(deps.ptr)
            self.kind = deps.kind
        elif isinstance(obj, DepRestrict):
            dep = <DepRestrict>obj
            self.ptr = C.pkgcraft_deprestrict_into_iter_flatten(dep.ptr)
            self.kind = dep.kind
        else:  # pragma: no cover
            raise TypeError(f"{obj.__class__.__name__!r} unsupported depset type")

    def __iter__(self):
        return self

    def __next__(self):
        ptr = C.pkgcraft_depset_into_iter_flatten_next(self.ptr)
        if ptr is not NULL:
            if self.kind == C.DEP_SET_KIND_ATOM:
                return Atom.from_ptr(<C.Atom *>ptr)
            elif self.kind == C.DEP_SET_KIND_STRING:
                c_str = <char *>ptr
                s = c_str.decode()
                C.pkgcraft_str_free(c_str)
                return s
            elif self.kind == C.DEP_SET_KIND_URI:
                return Uri.from_ptr(<C.Uri *>ptr)
            else:  # pragma: no cover
                raise TypeError(f'unknown DepSet kind: {self.kind}')
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_depset_into_iter_flatten_free(self.ptr)


cdef class _IntoIterRecursive:
    """Recursive iterator over a DepSet or DepRestrict object."""

    def __cinit__(self, object obj not None):
        if isinstance(obj, DepSet):
            deps = <DepSet>obj
            self.ptr = C.pkgcraft_depset_into_iter_recursive(deps.ptr)
            self.kind = deps.kind
        elif isinstance(obj, DepRestrict):
            dep = <DepRestrict>obj
            self.ptr = C.pkgcraft_deprestrict_into_iter_recursive(dep.ptr)
            self.kind = dep.kind
        else:  # pragma: no cover
            raise TypeError(f"{obj.__class__.__name__!r} unsupported depset type")

    def __iter__(self):
        return self

    def __next__(self):
        ptr = C.pkgcraft_depset_into_iter_recursive_next(self.ptr)
        if ptr is not NULL:
            return DepRestrict.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_depset_into_iter_recursive_free(self.ptr)


@cython.final
cdef class Uri(_IndirectInit):

    @staticmethod
    cdef Uri from_ptr(C.Uri *ptr):
        obj = <Uri>Uri.__new__(Uri)
        obj.ptr = ptr
        return obj

    @property
    def uri(self):
        if self._uri_str is None:
            c_str = C.pkgcraft_uri_uri(self.ptr)
            self._uri_str = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._uri_str

    @property
    def rename(self):
        c_str = C.pkgcraft_uri_rename(self.ptr)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    def __str__(self):
        c_str = C.pkgcraft_uri_str(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __dealloc__(self):
        C.pkgcraft_uri_free(self.ptr)
