from . cimport pkgcraft_c as C
from .atom cimport Atom
from .error import IndirectInit


cdef class DepRestrict:
    """Dependency restriction."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    @staticmethod
    cdef DepRestrict from_ptr(C.DepRestrict *r, DepSetType type):
        obj = <DepRestrict>DepRestrict.__new__(DepRestrict)
        obj._restrict = r
        obj._type = type
        return obj

    def flatten(self):
        """Iterate over the objects of a flattened DepRestrict."""
        yield from _DepSetFlatten.from_deprestrict(self)

    def __str__(self):
        c_str = C.pkgcraft_deprestrict_str(self._restrict)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __dealloc__(self):
        C.pkgcraft_deprestrict_free(self._restrict)


cdef class DepSet:
    """Dependency set of objects."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    @staticmethod
    cdef DepSet from_ptr(C.DepSet *deps, DepSetType type):
        obj = <DepSet>DepSet.__new__(DepSet)
        obj._deps = deps
        obj._type = type
        return obj

    def flatten(self):
        """Iterate over the objects of a flattened DepSet."""
        yield from _DepSetFlatten.from_depset(self)

    def __iter__(self):
        if self._iter is not NULL:
            C.pkgcraft_depset_iter_free(self._iter)
        self._iter = C.pkgcraft_depset_iter(self._deps)
        return self

    def __next__(self):
        # verify __iter__() was called since cython's generated next() method doesn't check
        if self._iter is NULL:
            raise TypeError(f"{self.__class__.__name__!r} object is not an iterator")

        d = C.pkgcraft_depset_iter_next(self._iter)
        if d is not NULL:
            return DepRestrict.from_ptr(d, self._type)
        raise StopIteration

    def __str__(self):
        c_str = C.pkgcraft_depset_str(self._deps)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __dealloc__(self):
        C.pkgcraft_depset_free(self._deps)
        C.pkgcraft_depset_iter_free(self._iter)


cdef class _DepSetFlatten:
    """Iterator over a flattened DepSet."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    @staticmethod
    cdef _DepSetFlatten from_deprestrict(DepRestrict d):
        o = <_DepSetFlatten>_DepSetFlatten.__new__(_DepSetFlatten)
        o._iter = C.pkgcraft_deprestrict_flatten_iter(d._restrict)
        o._type = d._type
        return o

    @staticmethod
    cdef _DepSetFlatten from_depset(DepSet d):
        o = <_DepSetFlatten>_DepSetFlatten.__new__(_DepSetFlatten)
        o._iter = C.pkgcraft_depset_flatten_iter(d._deps)
        o._type = d._type
        return o

    def __iter__(self):
        return self

    def __next__(self):
        # verify __iter__() was called since cython's generated next() method doesn't check
        if self._iter is NULL:  # pragma: no cover
            raise TypeError(f"{self.__class__.__name__!r} object is not an iterator")

        obj = C.pkgcraft_depset_flatten_iter_next(self._iter)
        if obj is not NULL:
            if self._type is DepSetAtom:
                return Atom.from_ptr(<const C.Atom *>obj)
            elif self._type is DepSetString:
                s = (<char *>obj).decode()
                C.pkgcraft_str_free(<char *>obj)
                return s
            elif self._type is DepSetUri:
                return Uri.from_ptr(<const C.Uri *>obj)
            else:
                raise AttributeError(f'unknown DepSet type: {self._type}')
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_depset_flatten_iter_free(self._iter)


cdef class Uri:

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    @staticmethod
    cdef Uri from_ptr(const C.Uri *uri):
        obj = <Uri>Uri.__new__(Uri)
        obj._uri = uri
        return obj

    @property
    def uri(self):
        if self._uri_str is None:
            c_str = C.pkgcraft_uri_uri(self._uri)
            self._uri_str = c_str.decode()
            C.pkgcraft_str_free(c_str)
        return self._uri_str

    @property
    def rename(self):
        c_str = C.pkgcraft_uri_rename(self._uri)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        return None

    def __str__(self):
        c_str = C.pkgcraft_uri_str(self._uri)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s
