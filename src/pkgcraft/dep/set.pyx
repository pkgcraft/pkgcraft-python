cimport cython

from .. cimport pkgcraft_c as C
from ..eapi cimport eapi_from_obj
from ..error cimport _IndirectInit
from .base cimport Dep
from .pkg cimport PkgDep

from ..error import PkgcraftError


cdef class DepSet(_IndirectInit):
    """Dependency set of objects."""

    @staticmethod
    cdef DepSet from_ptr(C.DepSet *ptr, DepSet obj=None):
        if ptr is not NULL:
            if obj is None:
                kind = ptr.kind
                if kind == C.DEP_SET_KIND_DEPENDENCIES:
                    obj = <Dependencies>Dependencies.__new__(Dependencies)
                elif kind == C.DEP_SET_KIND_RESTRICT:
                    obj = <Restrict>Restrict.__new__(Restrict)
                elif kind == C.DEP_SET_KIND_REQUIRED_USE:
                    obj = <RequiredUse>RequiredUse.__new__(RequiredUse)
                elif kind == C.DEP_SET_KIND_PROPERTIES:
                    obj = <Properties>Properties.__new__(Properties)
                elif kind == C.DEP_SET_KIND_SRC_URI:
                    obj = <SrcUri>SrcUri.__new__(SrcUri)
                elif kind == C.DEP_SET_KIND_LICENSE:
                    obj = <License>License.__new__(License)
                else:  # pragma: no cover
                    raise TypeError(f'unknown DepSet kind: {kind}')

            obj.ptr = ptr
            return obj
        return None

    def iter_flatten(self):
        """Iterate over the objects of a flattened DepSet."""
        yield from _IntoIterFlatten(self)

    def iter_recursive(self):
        """Recursively iterate over all Dep objects of a DepSet."""
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


@cython.final
cdef class Dependencies(DepSet):

    def __init__(self, str s="", eapi=None):
        cdef const C.Eapi *eapi_ptr = NULL
        if eapi is not None:
            eapi_ptr = eapi_from_obj(eapi).ptr

        ptr = C.pkgcraft_depset_dependencies(s.encode(), eapi_ptr)
        if ptr is NULL:
            raise PkgcraftError
        DepSet.from_ptr(ptr, self)


@cython.final
cdef class Restrict(DepSet):

    def __init__(self, str s=""):
        ptr = C.pkgcraft_depset_restrict(s.encode())
        if ptr is NULL:
            raise PkgcraftError
        DepSet.from_ptr(ptr, self)


@cython.final
cdef class RequiredUse(DepSet):

    def __init__(self, str s="", eapi=None):
        cdef const C.Eapi *eapi_ptr = NULL
        if eapi is not None:
            eapi_ptr = eapi_from_obj(eapi).ptr

        ptr = C.pkgcraft_depset_required_use(s.encode(), eapi_ptr)
        if ptr is NULL:
            raise PkgcraftError
        DepSet.from_ptr(ptr, self)


@cython.final
cdef class Properties(DepSet):

    def __init__(self, str s=""):
        ptr = C.pkgcraft_depset_properties(s.encode())
        if ptr is NULL:
            raise PkgcraftError
        DepSet.from_ptr(ptr, self)


@cython.final
cdef class SrcUri(DepSet):

    def __init__(self, str s="", eapi=None):
        cdef const C.Eapi *eapi_ptr = NULL
        if eapi is not None:
            eapi_ptr = eapi_from_obj(eapi).ptr

        ptr = C.pkgcraft_depset_src_uri(s.encode(), eapi_ptr)
        if ptr is NULL:
            raise PkgcraftError
        DepSet.from_ptr(ptr, self)


@cython.final
cdef class License(DepSet):

    def __init__(self, str s=""):
        ptr = C.pkgcraft_depset_license(s.encode())
        if ptr is NULL:
            raise PkgcraftError
        DepSet.from_ptr(ptr, self)


cdef class _IntoIter:
    """Iterator over a DepSet."""

    def __cinit__(self, DepSet d not None):
        self.ptr = C.pkgcraft_depset_into_iter(d.ptr)
        self.unit = d.ptr.unit

    def __iter__(self):
        return self

    def __next__(self):
        ptr = C.pkgcraft_depset_into_iter_next(self.ptr)
        if ptr is not NULL:
            return Dep.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_depset_into_iter_free(self.ptr)


cdef class _IntoIterFlatten:
    """Flattened iterator over a DepSet or Dep object."""

    def __cinit__(self, object obj not None):
        if isinstance(obj, DepSet):
            deps = <DepSet>obj
            self.ptr = C.pkgcraft_depset_into_iter_flatten(deps.ptr)
            self.unit = deps.ptr.unit
        elif isinstance(obj, Dep):
            dep = <Dep>obj
            self.ptr = C.pkgcraft_dep_into_iter_flatten(dep.ptr)
            self.unit = dep.ptr.unit
        else:  # pragma: no cover
            raise TypeError(f"{obj.__class__.__name__!r} unsupported depset type")

    def __iter__(self):
        return self

    def __next__(self):
        ptr = C.pkgcraft_depset_into_iter_flatten_next(self.ptr)
        if ptr is not NULL:
            if self.unit == C.DEP_UNIT_PKG_DEP:
                return PkgDep.from_ptr(<C.PkgDep *>ptr)
            elif self.unit == C.DEP_UNIT_STRING:
                c_str = <char *>ptr
                s = c_str.decode()
                C.pkgcraft_str_free(c_str)
                return s
            elif self.unit == C.DEP_UNIT_URI:
                return Uri.from_ptr(<C.Uri *>ptr)
            else:  # pragma: no cover
                raise TypeError(f'unknown DepSet unit: {self.unit}')
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_depset_into_iter_flatten_free(self.ptr)


cdef class _IntoIterRecursive:
    """Recursive iterator over a DepSet or Dep object."""

    def __cinit__(self, object obj not None):
        if isinstance(obj, DepSet):
            deps = <DepSet>obj
            self.ptr = C.pkgcraft_depset_into_iter_recursive(deps.ptr)
            self.unit = deps.ptr.unit
        elif isinstance(obj, Dep):
            dep = <Dep>obj
            self.ptr = C.pkgcraft_dep_into_iter_recursive(dep.ptr)
            self.unit = dep.ptr.unit
        else:  # pragma: no cover
            raise TypeError(f"{obj.__class__.__name__!r} unsupported depset type")

    def __iter__(self):
        return self

    def __next__(self):
        ptr = C.pkgcraft_depset_into_iter_recursive_next(self.ptr)
        if ptr is not NULL:
            return Dep.from_ptr(ptr)
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
