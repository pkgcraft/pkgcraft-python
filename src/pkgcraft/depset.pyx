from . cimport pkgcraft_c as C
from .atom cimport Atom
from .error import IndirectInit


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
        """Iterate over the objects of a flattened depset."""
        if self._type == DepSetType.Atom:
            yield from _DepSetFlattenAtom.create(self)
        elif self._type == DepSetType.String:
            yield from _DepSetFlattenString.create(self)
        elif self._type == DepSetType.Uri:
            yield from _DepSetFlattenUri.create(self)
        else:
            raise AttributeError(f'unknown DepSet type: {self._type}')

    def __str__(self):
        c_str = C.pkgcraft_depset_str(self._deps)
        s = c_str.decode()
        C.pkgcraft_str_free(c_str)
        return s

    def __dealloc__(self):
        C.pkgcraft_depset_free(self._deps)


cdef class _DepSetFlatten:
    """Iterator over a flattened DepSet."""

    def __init__(self):  # pragma: no cover
        raise IndirectInit(self)

    def __iter__(self):
        return self

    def __dealloc__(self):
        C.pkgcraft_depset_flatten_iter_free(self._iter)


cdef class _DepSetFlattenAtom(_DepSetFlatten):
    """Iterator over a flattened DepSet of atoms."""

    @staticmethod
    cdef _DepSetFlattenAtom create(DepSet d):
        o = <_DepSetFlattenAtom>_DepSetFlattenAtom.__new__(_DepSetFlattenAtom)
        o._iter = C.pkgcraft_depset_flatten_iter(d._deps)
        return o

    def __next__(self):
        # verify __iter__() was called since cython's generated next() method doesn't check
        if self._iter is NULL:  # pragma: no cover
            raise TypeError(f"{self.__class__.__name__!r} object is not an iterator")

        obj = C.pkgcraft_depset_flatten_iter_atom_next(self._iter)
        if obj is not NULL:
            return Atom.from_ptr(obj)
        raise StopIteration


cdef class _DepSetFlattenString(_DepSetFlatten):
    """Iterator over a flattened DepSet of strings."""

    @staticmethod
    cdef _DepSetFlattenString create(DepSet d):
        o = <_DepSetFlattenString>_DepSetFlattenString.__new__(_DepSetFlattenString)
        o._iter = C.pkgcraft_depset_flatten_iter(d._deps)
        return o

    def __next__(self):
        # verify __iter__() was called since cython's generated next() method doesn't check
        if self._iter is NULL:  # pragma: no cover
            raise TypeError(f"{self.__class__.__name__!r} object is not an iterator")

        c_str = C.pkgcraft_depset_flatten_iter_str_next(self._iter)
        if c_str is not NULL:
            s = c_str.decode()
            C.pkgcraft_str_free(c_str)
            return s
        raise StopIteration


cdef class _DepSetFlattenUri(_DepSetFlatten):
    """Iterator over a flattened DepSet of uris."""

    @staticmethod
    cdef _DepSetFlattenUri create(DepSet d):
        o = <_DepSetFlattenUri>_DepSetFlattenUri.__new__(_DepSetFlattenUri)
        o._iter = C.pkgcraft_depset_flatten_iter(d._deps)
        return o

    def __next__(self):
        # verify __iter__() was called since cython's generated next() method doesn't check
        if self._iter is NULL:  # pragma: no cover
            raise TypeError(f"{self.__class__.__name__!r} object is not an iterator")

        obj = C.pkgcraft_depset_flatten_iter_uri_next(self._iter)
        if obj is not NULL:
            # TODO: implement Uri object support
            raise NotImplementedError
        raise StopIteration
