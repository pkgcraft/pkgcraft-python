from collections.abc import Iterable
from enum import IntEnum

cimport cython
from cpython.mem cimport PyMem_Free, PyMem_Malloc

from .. cimport C
from .._misc cimport CStringArray, cstring_to_str
from ..eapi cimport Eapi
from ..error cimport Indirect
from ..types cimport OrderedFrozenSet
from .pkg cimport Dep

from ..error import PkgcraftError


class DepSetKind(IntEnum):
    Dependencies = C.DEP_SET_KIND_DEPENDENCIES
    License = C.DEP_SET_KIND_LICENSE
    Properties = C.DEP_SET_KIND_PROPERTIES
    RequiredUse = C.DEP_SET_KIND_REQUIRED_USE
    Restrict = C.DEP_SET_KIND_RESTRICT
    SrcUri = C.DEP_SET_KIND_SRC_URI


class DepSpecKind(IntEnum):
    Enabled = C.DEP_SPEC_KIND_ENABLED
    Disabled = C.DEP_SPEC_KIND_DISABLED
    AllOf = C.DEP_SPEC_KIND_ALL_OF
    AnyOf = C.DEP_SPEC_KIND_ANY_OF
    ExactlyOneOf = C.DEP_SPEC_KIND_EXACTLY_ONE_OF
    AtMostOneOf = C.DEP_SPEC_KIND_AT_MOST_ONE_OF
    UseEnabled = C.DEP_SPEC_KIND_USE_ENABLED
    UseDisabled = C.DEP_SPEC_KIND_USE_DISABLED


cdef list iterable_to_dep_specs(object obj, C.DepSetKind kind):
    """Convert an iterable to a list of DepSpec objects."""
    try:
        return [x if isinstance(x, DepSpec) else DepSpec(x, set=kind) for x in obj]
    except PkgcraftError:
        raise TypeError(f"invalid DepSpec iterable type: {obj.__class__.__name__}")


@cython.final
cdef class DepSpec:
    """Dependency object."""

    def __init__(self, object obj not None, /, eapi=None, set=DepSetKind.Dependencies):
        cdef const C.Eapi *eapi_ptr = NULL
        cdef C.DepSetKind kind = DepSetKind(set)

        if eapi is not None:
            eapi_ptr = Eapi._from_obj(eapi).ptr

        if isinstance(obj, str):
            ptr = C.pkgcraft_dep_spec_parse(obj.encode(), eapi_ptr, kind)
        elif isinstance(obj, Dep):
            ptr = C.pkgcraft_dep_spec_from_dep((<Dep>obj).ptr)
        else:
            raise TypeError(f"invalid DepSpec type: {obj.__class__.__name__!r}")

        if ptr is NULL:
            raise PkgcraftError

        self.set = DepSetKind(ptr.set)
        self.kind = DepSpecKind(ptr.kind)
        self.ptr = ptr

    @staticmethod
    cdef DepSpec from_ptr(C.DepSpec *ptr):
        """Create a DepSpec from a pointer and type."""
        inst = <DepSpec>DepSpec.__new__(DepSpec)
        inst.set = DepSetKind(ptr.set)
        inst.kind = DepSpecKind(ptr.kind)
        inst.ptr = ptr
        return inst

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

    def iter_conditionals(self):
        """Iterate over the conditionals of a DepSpec."""
        return _IntoIterConditionals.from_dep_spec(self.ptr)

    def iter_flatten(self):
        """Iterate over the objects of a flattened DepSpec."""
        return _IntoIterFlatten.from_dep_spec(self.ptr)

    def iter_recursive(self):
        """Recursively iterate over the DepSpec objects of a DepSpec."""
        return _IntoIterRecursive.from_dep_spec(self.ptr)

    def __contains__(self, obj):
        if isinstance(obj, DepSpec):
            return C.pkgcraft_dep_spec_contains_dep_spec(self.ptr, (<DepSpec>obj).ptr)
        return False

    def __iter__(self):
        return _IntoIter.from_dep_spec(self.ptr)

    def __reversed__(self):
        return _IntoIterReversed.from_dep_spec(self.ptr)

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
        kind = self.kind.name
        return f"<{name} {kind} '{self}' at 0x{addr:0x}>"

    def __dealloc__(self):
        C.pkgcraft_dep_spec_free(self.ptr)


cdef class DepSet:
    """Immutable set of dependency objects."""

    def __init__(self, obj=None, /, eapi=None, set=DepSetKind.Dependencies):
        cdef const C.Eapi *eapi_ptr = NULL
        cdef C.DepSetKind kind = DepSetKind(set)

        if isinstance(obj, str):
            if eapi is not None:
                eapi_ptr = Eapi._from_obj(eapi).ptr
            ptr = C.pkgcraft_dep_set_parse(str(obj).encode(), eapi_ptr, kind)
        elif isinstance(obj, DepSet):
            ptr = C.pkgcraft_dep_set_clone((<DepSet>obj).ptr)
        elif isinstance(obj, Iterable):
            ptr = DepSet.from_iter(obj, kind)
        elif obj is None:
            ptr = C.pkgcraft_dep_set_new(kind)
        else:
            raise TypeError(f"invalid DepSet type: {obj.__class__.__name__!r}")

        if ptr is NULL:
            raise PkgcraftError

        self.set = DepSetKind(ptr.set)
        self.ptr = ptr

    @staticmethod
    cdef DepSet from_ptr(C.DepSet *ptr):
        """Create a DepSet from a pointer."""
        inst = <DepSet>DepSet.__new__(DepSet)
        inst.set = DepSetKind(ptr.set)
        inst.ptr = ptr
        return inst

    cdef clone(self):
        """Clone a DepSet to a new object."""
        return self.create(C.pkgcraft_dep_set_clone(self.ptr))

    # TODO: use @classmethod once cdef methods support them
    cdef create(self, C.DepSet *ptr):
        """Create a DepSet from a pointer using the instance class."""
        if isinstance(self, MutableDepSet):
            return MutableDepSet.from_ptr(ptr)
        return DepSet.from_ptr(ptr)

    @staticmethod
    cdef C.DepSet *from_iter(object obj, C.DepSetKind kind):
        """Create a DepSet pointer from an iterable of DepSpec objects or strings."""
        # convert iterable to DepSpec objects
        if isinstance(obj, DepSpec):
            deps = [obj]
        else:
            deps = iterable_to_dep_specs(obj, kind)

        array = <C.DepSpec **> PyMem_Malloc(len(deps) * sizeof(C.DepSpec *))
        if not array:  # pragma: no cover
            raise MemoryError
        for (i, d) in enumerate(deps):
            array[i] = (<DepSpec>d).ptr
        ptr = C.pkgcraft_dep_set_from_iter(array, len(deps), kind)
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

        return self.create(ptr)

    def iter_conditionals(self):
        """Iterate over the conditionals of a DepSet."""
        return _IntoIterConditionals.from_dep_set(self.ptr)

    def iter_flatten(self):
        """Iterate over the objects of a flattened DepSet."""
        return _IntoIterFlatten.from_dep_set(self.ptr)

    def iter_recursive(self):
        """Recursively iterate over the DepSpec objects of a DepSet."""
        return _IntoIterRecursive.from_dep_set(self.ptr)

    def isdisjoint(self, other):
        cdef DepSet depset = None

        if isinstance(other, DepSet):
            depset = other
        else:
            depset = DepSet(other, set=self.set)

        return C.pkgcraft_dep_set_is_disjoint(self.ptr, depset.ptr)

    def issubset(self, other):
        cdef DepSet depset = None

        if isinstance(other, DepSet):
            depset = other
        else:
            depset = DepSet(other, set=self.set)

        return C.pkgcraft_dep_set_is_subset(self.ptr, depset.ptr)

    def issuperset(self, other):
        cdef DepSet depset = None

        if isinstance(other, DepSet):
            depset = other
        else:
            depset = DepSet(other, set=self.set)

        return C.pkgcraft_dep_set_is_subset(depset.ptr, self.ptr)

    def intersection(self, *others):
        depset = self.clone()

        for obj in others:
            if isinstance(obj, DepSet):
                depset &= obj
            else:
                depset &= DepSet(obj, set=self.set)

        return depset

    def union(self, *others):
        depset = self.clone()

        for obj in others:
            if isinstance(obj, DepSet):
                depset |= obj
            else:
                depset |= DepSet(obj, set=self.set)

        return depset

    def difference(self, *others):
        depset = self.clone()

        for obj in others:
            if isinstance(obj, DepSet):
                depset -= obj
            else:
                depset -= DepSet(obj, set=self.set)

        return depset

    def symmetric_difference(self, *others):
        depset = self.clone()

        for obj in others:
            if isinstance(obj, DepSet):
                depset ^= obj
            else:
                depset ^= DepSet(obj, set=self.set)

        return depset

    def __contains__(self, obj):
        cdef DepSpec dep = None

        if isinstance(obj, DepSpec):
            dep = obj
        elif isinstance(obj, str):
            dep = DepSpec(obj, set=self.set)

        if dep is not None:
            return C.pkgcraft_dep_set_contains_dep_spec(self.ptr, dep.ptr)
        return False

    def __iter__(self):
        return _IntoIter.from_dep_set(self.ptr)

    def __reversed__(self):
        return _IntoIterReversed.from_dep_set(self.ptr)

    def __getitem__(self, key):
        if isinstance(key, int):
            if key < 0:
                key = len(self) + key
            if key < 0 or key >= len(self):
                raise IndexError(f"{self.__class__.__name__} index out of range")
            if ptr := C.pkgcraft_dep_set_get_index(self.ptr, key):
                return DepSpec.from_ptr(ptr)
            raise PkgcraftError  # pragma: no cover
        elif isinstance(key, slice):
            deps = list(self)[key]
            return self.__class__(deps, set=self.set)
        raise TypeError(f"{self.__class__.__name__} indices must be integers or slices")

    def __bool__(self):
        return not C.pkgcraft_dep_set_is_empty(self.ptr)

    def __len__(self):
        return C.pkgcraft_dep_set_len(self.ptr)

    def __lt__(self, other):
        if isinstance(other, DepSet):
            return self <= other and self != other
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, DepSet):
            return C.pkgcraft_dep_set_is_subset(self.ptr, (<DepSet>other).ptr)
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, DepSet):
            return C.pkgcraft_dep_set_eq(self.ptr, (<DepSet>other).ptr)
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, DepSet):
            return C.pkgcraft_dep_set_is_subset((<DepSet>other).ptr, self.ptr)
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, DepSet):
            return self >= other and self != other
        return NotImplemented

    def __hash__(self):
        return C.pkgcraft_dep_set_hash(self.ptr)

    def __str__(self):
        return cstring_to_str(C.pkgcraft_dep_set_str(self.ptr))

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        set = self.set.name
        return f"<{name} {set} '{self}' at 0x{addr:0x}>"

    def __and__(self, other):
        op = C.SetOp.SET_OP_AND
        if isinstance(other, DepSet):
            obj = <DepSet>other
            if ptr := C.pkgcraft_dep_set_op_set(op, self.ptr, obj.ptr):
                return self.create(ptr)
            raise TypeError(f"unsupported DepSet types: {self.set.name} and {obj.set.name}")
        return NotImplemented

    def __rand__(self, other):
        return self.__and__(other)

    def __or__(self, other):
        op = C.SetOp.SET_OP_OR
        if isinstance(other, DepSet):
            obj = <DepSet>other
            if ptr := C.pkgcraft_dep_set_op_set(op, self.ptr, obj.ptr):
                return self.create(ptr)
            raise TypeError(f"unsupported DepSet types: {self.set.name} and {obj.set.name}")
        return NotImplemented

    def __ror__(self, other):
        return self.__or__(other)

    def __xor__(self, other):
        op = C.SetOp.SET_OP_XOR
        if isinstance(other, DepSet):
            obj = <DepSet>other
            if ptr := C.pkgcraft_dep_set_op_set(op, self.ptr, obj.ptr):
                return self.create(ptr)
            raise TypeError(f"unsupported DepSet types: {self.set.name} and {obj.set.name}")
        return NotImplemented

    def __rxor__(self, other):
        return self.__xor__(other)

    def __sub__(self, other):
        op = C.SetOp.SET_OP_SUB
        if isinstance(other, DepSet):
            obj = <DepSet>other
            if ptr := C.pkgcraft_dep_set_op_set(op, self.ptr, obj.ptr):
                return self.create(ptr)
            raise TypeError(f"unsupported DepSet types: {self.set.name} and {obj.set.name}")
        return NotImplemented

    def __rsub__(self, other):
        return self.__sub__(other)

    def __dealloc__(self):
        C.pkgcraft_dep_set_free(self.ptr)


@cython.final
cdef class MutableDepSet(DepSet):
    """Mutable set of dependency objects."""

    @staticmethod
    cdef MutableDepSet from_ptr(C.DepSet *ptr):
        """Create a MutableDepSet from a pointer."""
        inst = <MutableDepSet>MutableDepSet.__new__(MutableDepSet)
        inst.set = DepSetKind(ptr.set)
        inst.ptr = ptr
        return inst

    def sort(self):
        """Recursively sort a DepSet.

        >>> from pkgcraft.dep import MutableDepSet
        >>> d = MutableDepSet('a/c a/b')
        >>> str(d)
        'a/c a/b'
        >>> d.sort()
        >>> str(d)
        'a/b a/c'

        DepSpec objects are ordered by type and recursively sorted if possible.

        >>> d = MutableDepSet('( a/c a/b ( b/d b/c ) ) || ( a/c a/b ) a/z')
        >>> d.sort()
        >>> str(d)
        'a/z ( a/b a/c ( b/c b/d ) ) || ( a/c a/b )'
        """
        C.pkgcraft_dep_set_sort(self.ptr)

    def add(self, elem):
        cdef DepSpec value

        if isinstance(elem, DepSpec):
            value = elem
        else:
            value = DepSpec(elem, set=self.set)

        C.pkgcraft_dep_set_insert(self.ptr, value.ptr)

    def remove(self, elem):
        if isinstance(elem, DepSpec):
            obj = elem
        else:
            obj = DepSpec(elem, set=self.set)

        if obj in self:
            self.difference_update(obj)
        else:
            raise KeyError(elem)

    def discard(self, elem):
        if elem in self:
            self.difference_update(elem)

    def pop(self):
        if ptr := C.pkgcraft_dep_set_pop(self.ptr):
            return DepSpec.from_ptr(ptr)
        raise KeyError("pop from an empty DepSet")

    def clear(self):
        if self:
            self.intersection_update([])

    def update(self, *others):
        for obj in others:
            if isinstance(obj, DepSet):
                self |= obj
            else:
                self |= DepSet(obj, set=self.set)

        return self

    def intersection_update(self, *others):
        for obj in others:
            if isinstance(obj, DepSet):
                self &= obj
            else:
                self &= DepSet(obj, set=self.set)

        return self

    def difference_update(self, *others):
        for obj in others:
            if isinstance(obj, DepSet):
                self -= obj
            else:
                self -= DepSet(obj, set=self.set)

        return self

    def symmetric_difference_update(self, *others):
        for obj in others:
            if isinstance(obj, DepSet):
                self ^= obj
            else:
                self ^= DepSet(obj, set=self.set)

        return self

    def __iand__(self, other):
        op = C.SetOp.SET_OP_AND
        if isinstance(other, DepSet):
            obj = <DepSet>other
            if C.pkgcraft_dep_set_assign_op_set(op, self.ptr, obj.ptr):
                return self
            raise TypeError(f"unsupported DepSet types: {self.set.name} and {obj.set.name}")
        return NotImplemented

    def __ior__(self, other):
        op = C.SetOp.SET_OP_OR
        if isinstance(other, DepSet):
            obj = <DepSet>other
            if C.pkgcraft_dep_set_assign_op_set(op, self.ptr, obj.ptr):
                return self
            raise TypeError(f"unsupported DepSet types: {self.set.name} and {obj.set.name}")
        return NotImplemented

    def __ixor__(self, other):
        op = C.SetOp.SET_OP_XOR
        if isinstance(other, DepSet):
            obj = <DepSet>other
            if C.pkgcraft_dep_set_assign_op_set(op, self.ptr, obj.ptr):
                return self
            raise TypeError(f"unsupported DepSet types: {self.set.name} and {obj.set.name}")
        return NotImplemented

    def __isub__(self, other):
        op = C.SetOp.SET_OP_SUB
        if isinstance(other, DepSet):
            obj = <DepSet>other
            if C.pkgcraft_dep_set_assign_op_set(op, self.ptr, obj.ptr):
                return self
            raise TypeError(f"unsupported DepSet types: {self.set.name} and {obj.set.name}")
        return NotImplemented

    def __setitem__(self, key, value not None):
        cdef DepSpec dep_key
        cdef DepSpec dep_val

        if isinstance(key, int):
            if key < 0:
                key = len(self) + key
            if key < 0 or key >= len(self):
                raise IndexError(f"{self.__class__.__name__} index out of range")

            if isinstance(value, str):
                dep_val = DepSpec(value, set=self.set)
            else:
                dep_val = value

            if ptr := C.pkgcraft_dep_set_replace_index(self.ptr, key, dep_val.ptr):
                C.pkgcraft_dep_spec_free(ptr)
        elif isinstance(key, (DepSpec, str)):
            if isinstance(key, str):
                dep_key = DepSpec(key, set=self.set)
            else:
                dep_key = key

            if isinstance(value, str):
                dep_val = DepSpec(value, set=self.set)
            else:
                dep_val = value

            if ptr := C.pkgcraft_dep_set_replace(self.ptr, dep_key.ptr, dep_val.ptr):
                C.pkgcraft_dep_spec_free(ptr)
        elif isinstance(key, slice):
            deps = list(self)
            deps[key] = iterable_to_dep_specs(value, self.set)
            if set_ptr := DepSet.from_iter(deps, self.set):
                C.pkgcraft_dep_set_free(self.ptr)
                self.ptr = set_ptr
        else:
            raise TypeError(f"{self.__class__.__name__} indices must be integers or slices")

    # Override parent class to implicitly set __hash__ to None so hashing
    # raises TypeError and instances are correctly identified as unhashable
    # using `isinstance(obj, collections.abc.Hashable)`.
    def __eq__(self, other):
        return super().__eq__(other)


@cython.internal
cdef class _IntoIter(Indirect):
    """Iterator over a DepSet or DepSpec object."""

    cdef C.DepSpecIntoIter *ptr

    @staticmethod
    cdef _IntoIter from_dep_set(C.DepSet *ptr):
        inst = <_IntoIter>_IntoIter.__new__(_IntoIter)
        inst.ptr = C.pkgcraft_dep_set_into_iter(ptr)
        return inst

    @staticmethod
    cdef _IntoIter from_dep_spec(C.DepSpec *ptr):
        inst = <_IntoIter>_IntoIter.__new__(_IntoIter)
        inst.ptr = C.pkgcraft_dep_spec_into_iter(ptr)
        return inst

    def __iter__(self):
        return self

    def __next__(self):
        if ptr := C.pkgcraft_dep_set_into_iter_next(self.ptr):
            return DepSpec.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_dep_set_into_iter_free(self.ptr)


# TODO: re-merge with _IntoIter once @classmethod works with cdef functions for creation
@cython.internal
cdef class _IntoIterReversed(Indirect):
    """Reversed iterator over a DepSet or DepSpec object."""

    cdef C.DepSpecIntoIter *ptr

    @staticmethod
    cdef _IntoIterReversed from_dep_set(C.DepSet *ptr):
        inst = <_IntoIterReversed>_IntoIterReversed.__new__(_IntoIterReversed)
        inst.ptr = C.pkgcraft_dep_set_into_iter(ptr)
        return inst

    @staticmethod
    cdef _IntoIterReversed from_dep_spec(C.DepSpec *ptr):
        inst = <_IntoIterReversed>_IntoIterReversed.__new__(_IntoIterReversed)
        inst.ptr = C.pkgcraft_dep_spec_into_iter(ptr)
        return inst

    def __iter__(self):
        return self

    def __next__(self):
        if ptr := C.pkgcraft_dep_set_into_iter_next_back(self.ptr):
            return DepSpec.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_dep_set_into_iter_free(self.ptr)


@cython.internal
cdef class _IntoIterConditionals(Indirect):
    """Conditionals iterator over a DepSet or DepSpec object."""

    cdef C.DepSpecIntoIterConditionals *ptr

    @staticmethod
    cdef _IntoIterConditionals from_dep_set(C.DepSet *ptr):
        inst = <_IntoIterConditionals>_IntoIterConditionals.__new__(_IntoIterConditionals)
        inst.ptr = C.pkgcraft_dep_set_into_iter_conditionals(ptr)
        return inst

    @staticmethod
    cdef _IntoIterConditionals from_dep_spec(C.DepSpec *ptr):
        inst = <_IntoIterConditionals>_IntoIterConditionals.__new__(_IntoIterConditionals)
        inst.ptr = C.pkgcraft_dep_spec_into_iter_conditionals(ptr)
        return inst

    def __iter__(self):
        return self

    def __next__(self):
        if ptr := C.pkgcraft_dep_set_into_iter_conditionals_next(self.ptr):
            return cstring_to_str(<char *>ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_dep_set_into_iter_conditionals_free(self.ptr)


@cython.internal
cdef class _IntoIterFlatten(Indirect):
    """Flattened iterator over a DepSet or DepSpec object."""

    cdef C.DepSpecIntoIterFlatten *ptr
    cdef C.DepSetKind set

    @staticmethod
    cdef _IntoIterFlatten from_dep_set(C.DepSet *ptr):
        inst = <_IntoIterFlatten>_IntoIterFlatten.__new__(_IntoIterFlatten)
        inst.ptr = C.pkgcraft_dep_set_into_iter_flatten(ptr)
        inst.set = ptr.set
        return inst

    @staticmethod
    cdef _IntoIterFlatten from_dep_spec(C.DepSpec *ptr):
        inst = <_IntoIterFlatten>_IntoIterFlatten.__new__(_IntoIterFlatten)
        inst.ptr = C.pkgcraft_dep_spec_into_iter_flatten(ptr)
        inst.set = ptr.set
        return inst

    def __iter__(self):
        return self

    def __next__(self):
        if ptr := C.pkgcraft_dep_set_into_iter_flatten_next(self.ptr):
            if self.set == C.DEP_SET_KIND_DEPENDENCIES:
                return Dep.from_ptr(<C.Dep *>ptr)
            elif self.set == C.DEP_SET_KIND_SRC_URI:
                return Uri.from_ptr(<C.Uri *>ptr)
            else:
                return cstring_to_str(<char *>ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_dep_set_into_iter_flatten_free(self.ptr)


@cython.internal
cdef class _IntoIterRecursive(Indirect):
    """Recursive iterator over a DepSet or DepSpec object."""

    cdef C.DepSpecIntoIterRecursive *ptr

    @staticmethod
    cdef _IntoIterRecursive from_dep_set(C.DepSet *ptr):
        inst = <_IntoIterRecursive>_IntoIterRecursive.__new__(_IntoIterRecursive)
        inst.ptr = C.pkgcraft_dep_set_into_iter_recursive(ptr)
        return inst

    @staticmethod
    cdef _IntoIterRecursive from_dep_spec(C.DepSpec *ptr):
        inst = <_IntoIterRecursive>_IntoIterRecursive.__new__(_IntoIterRecursive)
        inst.ptr = C.pkgcraft_dep_spec_into_iter_recursive(ptr)
        return inst

    def __iter__(self):
        return self

    def __next__(self):
        if ptr := C.pkgcraft_dep_set_into_iter_recursive_next(self.ptr):
            return DepSpec.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_dep_set_into_iter_recursive_free(self.ptr)


@cython.final
cdef class Uri(Indirect):

    @staticmethod
    cdef Uri from_ptr(C.Uri *ptr):
        inst = <Uri>Uri.__new__(Uri)
        inst.ptr = ptr
        return inst

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
