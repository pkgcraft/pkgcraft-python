from collections.abc import Iterable

cimport cython
from cpython.mem cimport PyMem_Free, PyMem_Malloc

from .. cimport C
from .._misc cimport CStringArray, cstring_to_str
from ..eapi cimport Eapi
from ..error cimport _IndirectInit
from .pkg cimport Dep
from .spec cimport DepSpec

from ..error import PkgcraftError


cdef class DepSet(_IndirectInit):
    """Set of dependency objects."""

    @staticmethod
    cdef DepSet from_ptr(C.DepSet *ptr, DepSet obj=None):
        """Create a DepSet from a DepSet pointer."""
        if ptr is not NULL:
            if obj is None:
                if ptr.set == C.DEP_SET_KIND_DEPENDENCIES:
                    obj = <Dependencies>Dependencies.__new__(Dependencies)
                elif ptr.set == C.DEP_SET_KIND_LICENSE:
                    obj = <License>License.__new__(License)
                elif ptr.set == C.DEP_SET_KIND_PROPERTIES:
                    obj = <Properties>Properties.__new__(Properties)
                elif ptr.set == C.DEP_SET_KIND_REQUIRED_USE:
                    obj = <RequiredUse>RequiredUse.__new__(RequiredUse)
                elif ptr.set == C.DEP_SET_KIND_RESTRICT:
                    obj = <Restrict>Restrict.__new__(Restrict)
                elif ptr.set == C.DEP_SET_KIND_SRC_URI:
                    obj = <SrcUri>SrcUri.__new__(SrcUri)
                else:  # pragma: no cover
                    raise TypeError(f'unknown DepSet kind: {ptr.set}')
            obj.ptr = ptr
        return obj

    cdef C.DepSet *from_iter(self, object obj, C.DepSetKind kind):
        """Create a DepSet pointer from an iterable of DepSpec objects or strings."""
        # convert iterable to DepSpec objects
        objs = tuple(
            x if isinstance(x, DepSpec) else self.dep_spec(x)
            for x in obj
        )
        array = <C.DepSpec **> PyMem_Malloc(len(objs) * sizeof(C.DepSpec *))
        if not array:  # pragma: no cover
            raise MemoryError
        for (i, d) in enumerate(objs):
            array[i] = (<DepSpec>d).ptr
        ptr = C.pkgcraft_dep_set_from_iter(array, len(objs), kind)
        PyMem_Free(array)
        return ptr

    def evaluate(self, enabled=()):
        """Evaluate a DepSet using a given set of enabled options or by force."""
        if isinstance(enabled, bool):
            # forcible evaluation, enabling or disabling all conditionals
            ptr = C.pkgcraft_dep_set_evaluate_force(self.ptr, enabled)
        else:
            # use options to determine conditionals
            array = CStringArray(enabled)
            ptr = C.pkgcraft_dep_set_evaluate(self.ptr, array.ptr, len(array))

        return DepSet.from_ptr(ptr)

    def iter_flatten(self):
        """Iterate over the objects of a flattened DepSet."""
        yield from _IntoIterFlatten(self)

    def iter_recursive(self):
        """Recursively iterate over the DepSpec objects of a DepSet."""
        yield from _IntoIterRecursive(self)

    def __contains__(self, obj):
        cdef DepSpec dep = None

        if isinstance(obj, DepSpec):
            dep = obj
        elif isinstance(obj, str):
            dep = self.dep_spec(obj)

        if dep is not None:
            return C.pkgcraft_dep_set_contains(self.ptr, dep.ptr)
        return False

    def __iter__(self):
        return _IntoIter(self)

    def __len__(self):
        return C.pkgcraft_dep_set_len(self.ptr)

    def __bool__(self):
        return not C.pkgcraft_dep_set_is_empty(self.ptr)

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

    def __iand__(self, other):
        op = C.SetOp.SET_OP_AND
        if isinstance(other, self.__class__):
            C.pkgcraft_dep_set_assign_op_set(op, self.ptr, (<DepSet>other).ptr)
            return self
        else:
            return NotImplemented

    def __ior__(self, other):
        op = C.SetOp.SET_OP_OR
        if isinstance(other, self.__class__):
            C.pkgcraft_dep_set_assign_op_set(op, self.ptr, (<DepSet>other).ptr)
            return self
        else:
            return NotImplemented

    def __ixor__(self, other):
        op = C.SetOp.SET_OP_XOR
        if isinstance(other, self.__class__):
            C.pkgcraft_dep_set_assign_op_set(op, self.ptr, (<DepSet>other).ptr)
            return self
        else:
            return NotImplemented

    def __isub__(self, other):
        op = C.SetOp.SET_OP_SUB
        if isinstance(other, self.__class__):
            C.pkgcraft_dep_set_assign_op_set(op, self.ptr, (<DepSet>other).ptr)
            return self
        else:
            return NotImplemented

    def __and__(self, other):
        op = C.SetOp.SET_OP_AND
        if isinstance(other, self.__class__):
            return DepSet.from_ptr(C.pkgcraft_dep_set_op_set(op, self.ptr, (<DepSet>other).ptr))
        else:
            return NotImplemented

    def __rand__(self, other):
        if not isinstance(other, DepSet):
            return self.__and__(other)
        return NotImplemented

    def __or__(self, other):
        op = C.SetOp.SET_OP_OR
        if isinstance(other, self.__class__):
            return DepSet.from_ptr(C.pkgcraft_dep_set_op_set(op, self.ptr, (<DepSet>other).ptr))
        else:
            return NotImplemented

    def __ror__(self, other):
        if not isinstance(other, DepSet):
            return self.__or__(other)
        return NotImplemented

    def __xor__(self, other):
        op = C.SetOp.SET_OP_XOR
        if isinstance(other, self.__class__):
            return DepSet.from_ptr(C.pkgcraft_dep_set_op_set(op, self.ptr, (<DepSet>other).ptr))
        else:
            return NotImplemented

    def __rxor__(self, other):
        if not isinstance(other, DepSet):
            return self.__xor__(other)
        return NotImplemented

    def __sub__(self, other):
        op = C.SetOp.SET_OP_SUB
        if isinstance(other, self.__class__):
            return DepSet.from_ptr(C.pkgcraft_dep_set_op_set(op, self.ptr, (<DepSet>other).ptr))
        else:
            return NotImplemented

    def __rsub__(self, other):
        if not isinstance(other, DepSet):
            return self.__sub__(other)
        return NotImplemented

    def __dealloc__(self):
        C.pkgcraft_dep_set_free(self.ptr)


@cython.final
cdef class Dependencies(DepSet):

    def __init__(self, obj="", eapi=None):
        cdef const C.Eapi *eapi_ptr = NULL

        if isinstance(obj, str):
            if eapi is not None:
                eapi_ptr = Eapi._from_obj(eapi).ptr
            ptr = C.pkgcraft_dep_set_dependencies(str(obj).encode(), eapi_ptr)
        elif isinstance(obj, Iterable):
            ptr = self.from_iter(obj, C.DEP_SET_KIND_DEPENDENCIES)
        else:
            raise TypeError(f"invalid DepSet type: {obj.__class__.__name__!r}")

        if ptr is NULL:
            raise PkgcraftError

        DepSet.from_ptr(ptr, self)

    @staticmethod
    def dep_spec(str s not None, eapi=None):
        """Parse a dependency DepSpec."""
        cdef const C.Eapi *eapi_ptr = NULL
        if eapi is not None:
            eapi_ptr = Eapi._from_obj(eapi).ptr
        ptr = C.pkgcraft_dep_spec_dependencies(s.encode(), eapi_ptr)

        if ptr is NULL:
            raise PkgcraftError

        return DepSpec.from_ptr(ptr)


@cython.final
cdef class License(DepSet):

    def __init__(self, obj=""):
        if isinstance(obj, str):
            ptr = C.pkgcraft_dep_set_license(str(obj).encode())
        elif isinstance(obj, Iterable):
            ptr = self.from_iter(obj, C.DEP_SET_KIND_LICENSE)
        else:
            raise TypeError(f"invalid DepSet type: {obj.__class__.__name__!r}")

        if ptr is NULL:
            raise PkgcraftError

        DepSet.from_ptr(ptr, self)

    @staticmethod
    def dep_spec(str s not None):
        """Parse a LICENSE DepSpec."""
        ptr = C.pkgcraft_dep_spec_license(s.encode())

        if ptr is NULL:
            raise PkgcraftError

        return DepSpec.from_ptr(ptr)


@cython.final
cdef class Properties(DepSet):

    def __init__(self, obj=""):
        if isinstance(obj, str):
            ptr = C.pkgcraft_dep_set_properties(str(obj).encode())
        elif isinstance(obj, Iterable):
            ptr = self.from_iter(obj, C.DEP_SET_KIND_PROPERTIES)
        else:
            raise TypeError(f"invalid DepSet type: {obj.__class__.__name__!r}")

        if ptr is NULL:
            raise PkgcraftError

        DepSet.from_ptr(ptr, self)

    @staticmethod
    def dep_spec(str s not None):
        """Parse a PROPERTIES DepSpec."""
        ptr = C.pkgcraft_dep_spec_properties(s.encode())

        if ptr is NULL:
            raise PkgcraftError

        return DepSpec.from_ptr(ptr)


@cython.final
cdef class RequiredUse(DepSet):

    def __init__(self, obj="", eapi=None):
        cdef const C.Eapi *eapi_ptr = NULL

        if isinstance(obj, str):
            if eapi is not None:
                eapi_ptr = Eapi._from_obj(eapi).ptr
            ptr = C.pkgcraft_dep_set_required_use(str(obj).encode(), eapi_ptr)
        elif isinstance(obj, Iterable):
            ptr = self.from_iter(obj, C.DEP_SET_KIND_REQUIRED_USE)
        else:
            raise TypeError(f"invalid DepSet type: {obj.__class__.__name__!r}")

        if ptr is NULL:
            raise PkgcraftError

        DepSet.from_ptr(ptr, self)

    @staticmethod
    def dep_spec(str s not None, eapi=None):
        """Parse a REQUIRED_USE DepSpec."""
        cdef const C.Eapi *eapi_ptr = NULL
        if eapi is not None:
            eapi_ptr = Eapi._from_obj(eapi).ptr
        ptr = C.pkgcraft_dep_spec_required_use(s.encode(), eapi_ptr)

        if ptr is NULL:
            raise PkgcraftError

        return DepSpec.from_ptr(ptr)


@cython.final
cdef class Restrict(DepSet):

    def __init__(self, obj=""):
        if isinstance(obj, str):
            ptr = C.pkgcraft_dep_set_restrict(str(obj).encode())
        elif isinstance(obj, Iterable):
            ptr = self.from_iter(obj, C.DEP_SET_KIND_RESTRICT)
        else:
            raise TypeError(f"invalid DepSet type: {obj.__class__.__name__!r}")

        if ptr is NULL:
            raise PkgcraftError

        DepSet.from_ptr(ptr, self)

    @staticmethod
    def dep_spec(str s not None):
        """Parse a RESTRICT DepSpec."""
        ptr = C.pkgcraft_dep_spec_restrict(s.encode())

        if ptr is NULL:
            raise PkgcraftError

        return DepSpec.from_ptr(ptr)


@cython.final
cdef class SrcUri(DepSet):

    def __init__(self, obj="", eapi=None):
        cdef const C.Eapi *eapi_ptr = NULL

        if isinstance(obj, str):
            if eapi is not None:
                eapi_ptr = Eapi._from_obj(eapi).ptr
            ptr = C.pkgcraft_dep_set_src_uri(str(obj).encode(), eapi_ptr)
        elif isinstance(obj, Iterable):
            ptr = self.from_iter(obj, C.DEP_SET_KIND_SRC_URI)
        else:
            raise TypeError(f"invalid DepSet type: {obj.__class__.__name__!r}")

        if ptr is NULL:
            raise PkgcraftError

        DepSet.from_ptr(ptr, self)

    @staticmethod
    def dep_spec(str s not None, eapi=None):
        """Parse a SRC_URI DepSpec."""
        cdef const C.Eapi *eapi_ptr = NULL
        if eapi is not None:
            eapi_ptr = Eapi._from_obj(eapi).ptr
        ptr = C.pkgcraft_dep_spec_src_uri(s.encode(), eapi_ptr)

        if ptr is NULL:
            raise PkgcraftError

        return DepSpec.from_ptr(ptr)


cdef class _IntoIter:
    """Iterator over a DepSet or DepSpec object."""

    def __cinit__(self, object obj not None):
        if isinstance(obj, DepSet):
            self.ptr = C.pkgcraft_dep_set_into_iter((<DepSet>obj).ptr)
        elif isinstance(obj, DepSpec):
            self.ptr = C.pkgcraft_dep_spec_into_iter((<DepSpec>obj).ptr)
        else:  # pragma: no cover
            raise TypeError(f"{obj.__class__.__name__!r} unsupported dep type")

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
            self.set = deps.ptr.set
        elif isinstance(obj, DepSpec):
            dep = <DepSpec>obj
            self.ptr = C.pkgcraft_dep_spec_into_iter_flatten(dep.ptr)
            self.set = dep.ptr.set
        else:  # pragma: no cover
            raise TypeError(f"{obj.__class__.__name__!r} unsupported dep type")

    def __iter__(self):
        return self

    def __next__(self):
        ptr = C.pkgcraft_dep_set_into_iter_flatten_next(self.ptr)
        if ptr is not NULL:
            if self.set == C.DEP_SET_KIND_DEPENDENCIES:
                return Dep.from_ptr(<C.Dep *>ptr)
            elif self.set == C.DEP_SET_KIND_SRC_URI:
                return Uri.from_ptr(<C.Uri *>ptr)
            else:
                return cstring_to_str(<char *>ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_dep_set_into_iter_flatten_free(self.ptr)


cdef class _IntoIterRecursive:
    """Recursive iterator over a DepSet or DepSpec object."""

    def __cinit__(self, object obj not None):
        if isinstance(obj, DepSet):
            self.ptr = C.pkgcraft_dep_set_into_iter_recursive((<DepSet>obj).ptr)
        elif isinstance(obj, DepSpec):
            self.ptr = C.pkgcraft_dep_spec_into_iter_recursive((<DepSpec>obj).ptr)
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
