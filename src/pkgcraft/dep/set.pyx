cimport cython

from .. cimport C
from .._misc cimport cstring_to_str
from ..eapi cimport Eapi
from ..error cimport _IndirectInit
from .pkg cimport Dep
from .spec cimport DepSpec

from ..error import PkgcraftError


cdef class DepSet(_IndirectInit):
    """Set of dependency objects."""

    @staticmethod
    cdef DepSet from_ptr(C.DepSet *ptr, DepSet obj=None):
        if ptr is not NULL:
            if obj is None:
                if ptr.kind == C.DEP_SET_KIND_DEPENDENCIES:
                    obj = <Dependencies>Dependencies.__new__(Dependencies)
                elif ptr.kind == C.DEP_SET_KIND_LICENSE:
                    obj = <License>License.__new__(License)
                elif ptr.kind == C.DEP_SET_KIND_PROPERTIES:
                    obj = <Properties>Properties.__new__(Properties)
                elif ptr.kind == C.DEP_SET_KIND_REQUIRED_USE:
                    obj = <RequiredUse>RequiredUse.__new__(RequiredUse)
                elif ptr.kind == C.DEP_SET_KIND_RESTRICT:
                    obj = <Restrict>Restrict.__new__(Restrict)
                elif ptr.kind == C.DEP_SET_KIND_SRC_URI:
                    obj = <SrcUri>SrcUri.__new__(SrcUri)
                else:  # pragma: no cover
                    raise TypeError(f'unknown DepSet kind: {ptr.kind}')
            obj.ptr = ptr
        return obj

    def iter_flatten(self):
        """Iterate over the objects of a flattened DepSet."""
        yield from _IntoIterFlatten(self)

    def iter_recursive(self):
        """Recursively iterate over the DepSpec objects of a DepSpec."""
        yield from _IntoIterRecursive(self)

    def __iter__(self):
        return _IntoIter(self)

    def __eq__(self, other):
        if isinstance(other, DepSet):
            return C.pkgcraft_dep_set_eq(self.ptr, (<DepSet>other).ptr)
        return NotImplemented

    def __hash__(self):
        return C.pkgcraft_dep_set_hash(self.ptr)

    def __str__(self):
        return cstring_to_str(C.pkgcraft_dep_set_str(self.ptr))

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __dealloc__(self):
        C.pkgcraft_dep_set_free(self.ptr)


@cython.final
cdef class Dependencies(DepSet):

    def __init__(self, str s="", eapi=None):
        cdef const C.Eapi *eapi_ptr = NULL
        if eapi is not None:
            eapi_ptr = Eapi._from_obj(eapi).ptr

        ptr = C.pkgcraft_dep_set_dependencies(s.encode(), eapi_ptr)
        if ptr is NULL:
            raise PkgcraftError
        DepSet.from_ptr(ptr, self)


@cython.final
cdef class License(DepSet):

    def __init__(self, str s=""):
        ptr = C.pkgcraft_dep_set_license(s.encode())
        if ptr is NULL:
            raise PkgcraftError
        DepSet.from_ptr(ptr, self)


@cython.final
cdef class Properties(DepSet):

    def __init__(self, str s=""):
        ptr = C.pkgcraft_dep_set_properties(s.encode())
        if ptr is NULL:
            raise PkgcraftError
        DepSet.from_ptr(ptr, self)


@cython.final
cdef class RequiredUse(DepSet):

    def __init__(self, str s="", eapi=None):
        cdef const C.Eapi *eapi_ptr = NULL
        if eapi is not None:
            eapi_ptr = Eapi._from_obj(eapi).ptr

        ptr = C.pkgcraft_dep_set_required_use(s.encode(), eapi_ptr)
        if ptr is NULL:
            raise PkgcraftError
        DepSet.from_ptr(ptr, self)


@cython.final
cdef class Restrict(DepSet):

    def __init__(self, str s=""):
        ptr = C.pkgcraft_dep_set_restrict(s.encode())
        if ptr is NULL:
            raise PkgcraftError
        DepSet.from_ptr(ptr, self)


@cython.final
cdef class SrcUri(DepSet):

    def __init__(self, str s="", eapi=None):
        cdef const C.Eapi *eapi_ptr = NULL
        if eapi is not None:
            eapi_ptr = Eapi._from_obj(eapi).ptr

        ptr = C.pkgcraft_dep_set_src_uri(s.encode(), eapi_ptr)
        if ptr is NULL:
            raise PkgcraftError
        DepSet.from_ptr(ptr, self)


cdef class _IntoIter:
    """Iterator over a DepSet."""

    def __cinit__(self, DepSet d not None):
        self.ptr = C.pkgcraft_dep_set_into_iter(d.ptr)
        self.unit = d.ptr.unit

    def __iter__(self):
        return self

    def __next__(self):
        ptr = C.pkgcraft_dep_set_into_iter_next(self.ptr)
        if ptr is not NULL:
            return DepSpec.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_dep_set_into_iter_free(self.ptr)


cdef class _IntoIterFlatten:
    """Flattened iterator over a DepSet or DepSpec object."""

    def __cinit__(self, object obj not None):
        if isinstance(obj, DepSet):
            deps = <DepSet>obj
            self.ptr = C.pkgcraft_dep_set_into_iter_flatten(deps.ptr)
            self.unit = deps.ptr.unit
        elif isinstance(obj, DepSpec):
            dep = <DepSpec>obj
            self.ptr = C.pkgcraft_dep_spec_into_iter_flatten(dep.ptr)
            self.unit = dep.ptr.unit
        else:  # pragma: no cover
            raise TypeError(f"{obj.__class__.__name__!r} unsupported dep type")

    def __iter__(self):
        return self

    def __next__(self):
        ptr = C.pkgcraft_dep_set_into_iter_flatten_next(self.ptr)
        if ptr is not NULL:
            if self.unit == C.DEP_SPEC_UNIT_DEP:
                return Dep.from_ptr(<C.Dep *>ptr)
            elif self.unit == C.DEP_SPEC_UNIT_STRING:
                return cstring_to_str(<char *>ptr)
            elif self.unit == C.DEP_SPEC_UNIT_URI:
                return Uri.from_ptr(<C.Uri *>ptr)
            else:  # pragma: no cover
                raise TypeError(f'unknown DepSet unit: {self.unit}')
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_dep_set_into_iter_flatten_free(self.ptr)


cdef class _IntoIterRecursive:
    """Recursive iterator over a DepSet or DepSpec object."""

    def __cinit__(self, object obj not None):
        if isinstance(obj, DepSet):
            deps = <DepSet>obj
            self.ptr = C.pkgcraft_dep_set_into_iter_recursive(deps.ptr)
        elif isinstance(obj, DepSpec):
            dep = <DepSpec>obj
            self.ptr = C.pkgcraft_dep_spec_into_iter_recursive(dep.ptr)
        else:  # pragma: no cover
            raise TypeError(f"{obj.__class__.__name__!r} unsupported dep type")

    def __iter__(self):
        return self

    def __next__(self):
        ptr = C.pkgcraft_dep_set_into_iter_recursive_next(self.ptr)
        if ptr is not NULL:
            return DepSpec.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_dep_set_into_iter_recursive_free(self.ptr)


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
            self._uri_str = cstring_to_str(C.pkgcraft_uri_uri(self.ptr))
        return self._uri_str

    @property
    def filename(self):
        return cstring_to_str(C.pkgcraft_uri_filename(self.ptr))

    def __str__(self):
        return cstring_to_str(C.pkgcraft_uri_str(self.ptr))

    def __dealloc__(self):
        C.pkgcraft_uri_free(self.ptr)
