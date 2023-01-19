cimport cython

from . cimport pkgcraft_c as C
from .atom cimport Atom
from .error cimport _IndirectInit


@cython.final
cdef class DepRestrict(_IndirectInit):
    """Dependency restriction."""

    @staticmethod
    cdef DepRestrict from_ptr(C.DepRestrict *ptr, DepSetKind kind):
        obj = <DepRestrict>DepRestrict.__new__(DepRestrict)
        obj.ptr = ptr
        obj.kind = kind
        return obj

    def __iter__(self):
        return _IntoIterFlatten(self, self.kind)

    def __lt__(self, DepRestrict other):
        return C.pkgcraft_deprestrict_cmp(self.ptr, other.ptr) == -1

    def __le__(self, DepRestrict other):
        return C.pkgcraft_deprestrict_cmp(self.ptr, other.ptr) <= 0

    def __eq__(self, DepRestrict other):
        return C.pkgcraft_deprestrict_cmp(self.ptr, other.ptr) == 0

    def __ne__(self, DepRestrict other):
        return C.pkgcraft_deprestrict_cmp(self.ptr, other.ptr) != 0

    def __ge__(self, DepRestrict other):
        return C.pkgcraft_deprestrict_cmp(self.ptr, other.ptr) >= 0

    def __gt__(self, DepRestrict other):
        return C.pkgcraft_deprestrict_cmp(self.ptr, other.ptr) == 1

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
    cdef DepSet from_ptr(C.DepSet *ptr, DepSetKind kind):
        if ptr is not NULL:
            obj = <DepSet>DepSet.__new__(DepSet)
            obj.ptr = ptr
            obj.kind = kind
            return obj
        return None

    def iter_flatten(self):
        """Iterate over the objects of a flattened DepSet."""
        yield from _IntoIterFlatten(self, self.kind)

    def __iter__(self):
        return _IntoIter(self)

    def __eq__(self, DepSet other):
        return C.pkgcraft_depset_eq(self.ptr, other.ptr)

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

    def __cinit__(self, DepSet d):
        self.ptr = C.pkgcraft_depset_into_iter(d.ptr)
        self.kind = d.kind

    def __iter__(self):
        return self

    def __next__(self):
        ptr = C.pkgcraft_depset_into_iter_next(self.ptr)
        if ptr is not NULL:
            return DepRestrict.from_ptr(ptr, self.kind)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_depset_into_iter_free(self.ptr)


cdef class _IntoIterFlatten:
    """Iterator over a flattened DepSet."""

    def __cinit__(self, object obj, DepSetKind kind):
        if isinstance(obj, DepSet):
            self.ptr = C.pkgcraft_depset_into_iter_flatten((<DepSet>obj).ptr)
        elif isinstance(obj, DepRestrict):
            self.ptr = C.pkgcraft_deprestrict_into_iter_flatten((<DepRestrict>obj).ptr)
        else:  # pragma: no cover
            raise TypeError(f"{obj.__class__.__name__!r} unsupported depset type")

        self.kind = kind

    def __iter__(self):
        return self

    def __next__(self):
        ptr = C.pkgcraft_depset_into_iter_flatten_next(self.ptr)
        if ptr is not NULL:
            if self.kind == DepSetAtom:
                return Atom.from_ptr(<C.Atom *>ptr)
            elif self.kind == DepSetString:
                c_str = <char *>ptr
                s = c_str.decode()
                C.pkgcraft_str_free(c_str)
                return s
            elif self.kind == DepSetUri:
                return Uri.from_ptr(<C.Uri *>ptr)
            else:  # pragma: no cover
                raise TypeError(f'unknown DepSet kind: {self.kind}')
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_depset_into_iter_flatten_free(self.ptr)


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
