cimport cython

from . cimport pkgcraft_c as C
from .atom cimport Atom
from .error import IndirectInit


@cython.final
cdef class DepRestrict:
    """Dependency restriction."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    @staticmethod
    cdef DepRestrict from_ptr(C.DepRestrict *ptr, DepSetKind kind):
        obj = <DepRestrict>DepRestrict.__new__(DepRestrict)
        obj.ptr = ptr
        obj.kind = kind
        return obj

    def flatten(self):
        """Iterate over the objects of a flattened DepRestrict."""
        iter = C.pkgcraft_deprestrict_flatten_iter(self.ptr)
        yield from _DepSetFlatten.from_ptr(iter, self.kind)

    def __str__(self):
        c_str = C.pkgcraft_deprestrict_str(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __dealloc__(self):
        C.pkgcraft_deprestrict_free(self.ptr)


@cython.final
cdef class DepSet:
    """Dependency set of objects."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    @staticmethod
    cdef DepSet from_ptr(C.DepSet *ptr, DepSetKind kind):
        obj = <DepSet>DepSet.__new__(DepSet)
        obj.ptr = ptr
        obj.kind = kind
        return obj

    def flatten(self):
        """Iterate over the objects of a flattened DepSet."""
        ptr = C.pkgcraft_depset_flatten_iter(self.ptr)
        yield from _DepSetFlatten.from_ptr(ptr, self.kind)

    def __iter__(self):
        if self.iter_ptr is not NULL:
            C.pkgcraft_depset_iter_free(self.iter_ptr)
        self.iter_ptr = C.pkgcraft_depset_iter(self.ptr)
        return self

    def __next__(self):
        # verify __iter__() was called since cython's generated next() method doesn't check
        if self.iter_ptr is NULL:
            raise TypeError(f"{self.__class__.__name__!r} object is not an iterator")

        d = C.pkgcraft_depset_iter_next(self.iter_ptr)
        if d is not NULL:
            return DepRestrict.from_ptr(d, self.kind)
        raise StopIteration

    def __str__(self):
        c_str = C.pkgcraft_depset_str(self.ptr)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __dealloc__(self):
        C.pkgcraft_depset_free(self.ptr)
        C.pkgcraft_depset_iter_free(self.iter_ptr)


cdef class _DepSetFlatten:
    """Iterator over a flattened DepSet."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    @staticmethod
    cdef _DepSetFlatten from_ptr(C.DepSetFlatten *ptr, DepSetKind kind):
        o = <_DepSetFlatten>_DepSetFlatten.__new__(_DepSetFlatten)
        o.ptr = ptr
        o.kind = kind
        return o

    def __iter__(self):
        return self

    def __next__(self):
        # verify __iter__() was called since cython's generated next() method doesn't check
        if self.ptr is NULL:  # pragma: no cover
            raise TypeError(f"{self.__class__.__name__!r} object is not an iterator")

        obj = C.pkgcraft_depset_flatten_iter_next(self.ptr)
        if obj is not NULL:
            if self.kind is DepSetAtom:
                return Atom.from_ptr(<const C.Atom *>obj)
            elif self.kind is DepSetString:
                s = (<char *>obj).decode()
                C.pkgcraft_str_free(<char *>obj)
                return s
            elif self.kind is DepSetUri:
                return Uri.from_ptr(<const C.Uri *>obj)
            else:  # pragma: no cover
                raise AttributeError(f'unknown DepSet kind: {self.kind}')
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_depset_flatten_iter_free(self.ptr)


@cython.final
cdef class Uri:

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    @staticmethod
    cdef Uri from_ptr(const C.Uri *ptr):
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
