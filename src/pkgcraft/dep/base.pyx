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
from .uri cimport Uri
from .use_dep cimport UseDep

from ..error import PkgcraftError


class DependencySetKind(IntEnum):
    Package = C.DEPENDENCY_SET_KIND_PACKAGE
    License = C.DEPENDENCY_SET_KIND_LICENSE
    Properties = C.DEPENDENCY_SET_KIND_PROPERTIES
    RequiredUse = C.DEPENDENCY_SET_KIND_REQUIRED_USE
    Restrict = C.DEPENDENCY_SET_KIND_RESTRICT
    SrcUri = C.DEPENDENCY_SET_KIND_SRC_URI


class DependencyKind(IntEnum):
    Enabled = C.DEPENDENCY_KIND_ENABLED
    Disabled = C.DEPENDENCY_KIND_DISABLED
    AllOf = C.DEPENDENCY_KIND_ALL_OF
    AnyOf = C.DEPENDENCY_KIND_ANY_OF
    ExactlyOneOf = C.DEPENDENCY_KIND_EXACTLY_ONE_OF
    AtMostOneOf = C.DEPENDENCY_KIND_AT_MOST_ONE_OF
    Conditional = C.DEPENDENCY_KIND_CONDITIONAL


cdef list iterable_to_dependencies(object obj, C.DependencySetKind kind):
    """Convert an iterable to a list of Dependency objects."""
    try:
        return [x if isinstance(x, Dependency) else Dependency(x, set=kind) for x in obj]
    except PkgcraftError:
        raise TypeError(f"invalid Dependency iterable type: {obj.__class__.__name__}")


@cython.final
cdef class Dependency:
    """Dependency object."""

    def __init__(self, object obj not None, /, eapi=None, set=DependencySetKind.Package):
        cdef const C.Eapi *eapi_ptr = NULL
        cdef C.DependencySetKind kind = DependencySetKind(set)

        if eapi is not None:
            eapi_ptr = Eapi._from_obj(eapi).ptr

        if isinstance(obj, str):
            ptr = C.pkgcraft_dependency_parse(obj.encode(), eapi_ptr, kind)
        elif isinstance(obj, Dep):
            ptr = C.pkgcraft_dependency_from_dep((<Dep>obj).ptr)
        else:
            raise TypeError(f"invalid Dependency type: {obj.__class__.__name__!r}")

        if ptr is NULL:
            raise PkgcraftError

        Dependency.from_ptr(ptr, self)

    @staticmethod
    cdef Dependency from_ptr(C.Dependency *ptr, Dependency inst = None):
        """Create a Dependency from a pointer and type."""
        if inst is None:
            inst = <Dependency>Dependency.__new__(Dependency)
        inst.set = DependencySetKind(ptr.set)
        inst.kind = DependencyKind(ptr.kind)
        inst.ptr = ptr
        return inst

    @classmethod
    def package(cls, s: str = None, eapi: Eapi | str = None):
        """Parse a string into a package dependency."""
        return cls(s, eapi, set=DependencySetKind.Package)

    @classmethod
    def license(cls, s: str = None):
        """Parse a string into a LICENSE dependency."""
        return cls(s, set=DependencySetKind.License)

    @classmethod
    def properties(cls, s: str = None):
        """Parse a string into a PROPERTIES dependency."""
        return cls(s, set=DependencySetKind.Properties)

    @classmethod
    def required_use(cls, s: str = None):
        """Parse a string into a REQUIRED_USE dependency."""
        return cls(s, set=DependencySetKind.RequiredUse)

    @classmethod
    def restrict(cls, s: str = None):
        """Parse a string into a RESTRICT dependency."""
        return cls(s, set=DependencySetKind.Restrict)

    @classmethod
    def src_uri(cls, s: str = None):
        """Parse a string into a SRC_URI dependency."""
        return cls(s, set=DependencySetKind.SrcUri)

    @property
    def conditional(self):
        """Return the conditional UseDep for a Dependency if it exists."""
        if self.kind == DependencyKind.Conditional:
            return UseDep.from_ptr(C.pkgcraft_dependency_conditional(self.ptr))
        return None

    def evaluate(self, enabled=()):
        """Evaluate a Dependency using a given set of enabled options or by force."""
        cdef size_t length

        if isinstance(enabled, bool):
            # forcible evaluation, enabling or disabling all conditionals
            ptrs = C.pkgcraft_dependency_evaluate_force(self.ptr, enabled, &length)
        else:
            # use options to determine conditionals
            opts = CStringArray(enabled)
            ptrs = C.pkgcraft_dependency_evaluate(self.ptr, opts.ptr, len(opts), &length)

        deps = OrderedFrozenSet(Dependency.from_ptr(ptrs[i]) for i in range(length))
        C.pkgcraft_array_free(<void **>ptrs, length)
        return deps

    def iter_conditionals(self):
        """Iterate over the conditionals of a Dependency."""
        return _IntoIterConditionals.from_dependency(self.ptr)

    def iter_flatten(self):
        """Iterate over the objects of a flattened Dependency."""
        return _IntoIterFlatten.from_dependency(self.ptr)

    def iter_recursive(self):
        """Recursively iterate over the Dependency objects of a Dependency."""
        return _IntoIterRecursive.from_dependency(self.ptr)

    def __contains__(self, obj):
        if isinstance(obj, Dependency):
            return C.pkgcraft_dependency_contains_dependency(self.ptr, (<Dependency>obj).ptr)
        elif isinstance(obj, str):
            return C.pkgcraft_dependency_contains_str(self.ptr, obj.encode())
        elif isinstance(obj, UseDep):
            return C.pkgcraft_dependency_contains_use_dep(self.ptr, (<UseDep>obj).ptr)
        return False

    def __iter__(self):
        return _IntoIter.from_dependency(self.ptr)

    def __reversed__(self):
        return _IntoIterReversed.from_dependency(self.ptr)

    def __len__(self):
        return C.pkgcraft_dependency_len(self.ptr)

    def __lt__(self, other):
        if isinstance(other, Dependency):
            return C.pkgcraft_dependency_cmp(self.ptr, (<Dependency>other).ptr) == -1
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, Dependency):
            return C.pkgcraft_dependency_cmp(self.ptr, (<Dependency>other).ptr) <= 0
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, Dependency):
            return C.pkgcraft_dependency_cmp(self.ptr, (<Dependency>other).ptr) == 0
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, Dependency):
            return C.pkgcraft_dependency_cmp(self.ptr, (<Dependency>other).ptr) != 0
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, Dependency):
            return C.pkgcraft_dependency_cmp(self.ptr, (<Dependency>other).ptr) >= 0
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, Dependency):
            return C.pkgcraft_dependency_cmp(self.ptr, (<Dependency>other).ptr) == 1
        return NotImplemented

    def __hash__(self):
        return C.pkgcraft_dependency_hash(self.ptr)

    def __str__(self):
        return cstring_to_str(C.pkgcraft_dependency_str(self.ptr))

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        kind = self.kind.name
        return f"<{name} {kind} '{self}' at 0x{addr:0x}>"

    def __dealloc__(self):
        C.pkgcraft_dependency_free(self.ptr)


cdef class DependencySet:
    """Immutable set of dependency objects."""

    def __init__(self, obj=None, /, eapi=None, set=DependencySetKind.Package):
        cdef const C.Eapi *eapi_ptr = NULL
        cdef C.DependencySetKind kind = DependencySetKind(set)

        if isinstance(obj, str):
            if eapi is not None:
                eapi_ptr = Eapi._from_obj(eapi).ptr
            ptr = C.pkgcraft_dependency_set_parse(str(obj).encode(), eapi_ptr, kind)
        elif isinstance(obj, DependencySet):
            ptr = C.pkgcraft_dependency_set_clone((<DependencySet>obj).ptr)
        elif isinstance(obj, Iterable):
            ptr = DependencySet.from_iter(obj, kind)
        elif obj is None:
            ptr = C.pkgcraft_dependency_set_new(kind)
        else:
            raise TypeError(f"invalid DependencySet type: {obj.__class__.__name__!r}")

        if ptr is NULL:
            raise PkgcraftError

        DependencySet.from_ptr(ptr, self)

    @staticmethod
    cdef DependencySet from_ptr(C.DependencySet *ptr, DependencySet inst = None):
        """Create a DependencySet from a pointer."""
        if inst is None:
            inst = <DependencySet>DependencySet.__new__(DependencySet)
        inst.set = DependencySetKind(ptr.set)
        inst.ptr = ptr
        return inst

    cdef clone(self):
        """Clone a DependencySet to a new object."""
        return self.create(C.pkgcraft_dependency_set_clone(self.ptr))

    # TODO: use @classmethod once cdef methods support them
    # See https://github.com/cython/cython/issues/1271.
    cdef create(self, C.DependencySet *ptr):
        """Create a DependencySet from a pointer using the instance class."""
        if isinstance(self, MutableDependencySet):
            return MutableDependencySet.from_ptr(ptr)
        return DependencySet.from_ptr(ptr)

    @staticmethod
    cdef C.DependencySet *from_iter(object obj, C.DependencySetKind kind):
        """Create a DependencySet pointer from an iterable of Dependency objects or strings."""
        # convert iterable to Dependency objects
        if isinstance(obj, Dependency):
            deps = [obj]
        else:
            deps = iterable_to_dependencies(obj, kind)

        array = <C.Dependency **> PyMem_Malloc(len(deps) * sizeof(C.Dependency *))
        if not array:  # pragma: no cover
            raise MemoryError
        for (i, d) in enumerate(deps):
            array[i] = (<Dependency>d).ptr
        ptr = C.pkgcraft_dependency_set_from_iter(array, len(deps), kind)
        PyMem_Free(array)
        return ptr

    @classmethod
    def package(cls, s: str = None, eapi: Eapi | str = None):
        """Parse a string into a package dependency set."""
        return cls(s, eapi, set=DependencySetKind.Package)

    @classmethod
    def license(cls, s: str = None):
        """Parse a string into a LICENSE dependency set."""
        return cls(s, set=DependencySetKind.License)

    @classmethod
    def properties(cls, s: str = None):
        """Parse a string into a PROPERTIES dependency set."""
        return cls(s, set=DependencySetKind.Properties)

    @classmethod
    def required_use(cls, s: str = None):
        """Parse a string into a REQUIRED_USE dependency set."""
        return cls(s, set=DependencySetKind.RequiredUse)

    @classmethod
    def restrict(cls, s: str = None):
        """Parse a string into a RESTRICT dependency set."""
        return cls(s, set=DependencySetKind.Restrict)

    @classmethod
    def src_uri(cls, s: str = None):
        """Parse a string into a SRC_URI dependency set."""
        return cls(s, set=DependencySetKind.SrcUri)

    def evaluate(self, enabled=()):
        """Evaluate a DependencySet using a given set of enabled options or by force."""
        if isinstance(enabled, bool):
            # forcible evaluation, enabling or disabling all conditionals
            ptr = C.pkgcraft_dependency_set_evaluate_force(self.ptr, enabled)
        else:
            # use options to determine conditionals
            array = CStringArray(enabled)
            ptr = C.pkgcraft_dependency_set_evaluate(self.ptr, array.ptr, len(array))

        return self.create(ptr)

    def iter_conditionals(self):
        """Iterate over the conditionals of a DependencySet."""
        return _IntoIterConditionals.from_dependency_set(self.ptr)

    def iter_flatten(self):
        """Iterate over the objects of a flattened DependencySet."""
        return _IntoIterFlatten.from_dependency_set(self.ptr)

    def iter_recursive(self):
        """Recursively iterate over the Dependency objects of a DependencySet."""
        return _IntoIterRecursive.from_dependency_set(self.ptr)

    def isdisjoint(self, other):
        cdef DependencySet depset = None

        if isinstance(other, DependencySet):
            depset = other
        else:
            depset = DependencySet(other, set=self.set)

        return C.pkgcraft_dependency_set_is_disjoint(self.ptr, depset.ptr)

    def issubset(self, other):
        cdef DependencySet depset = None

        if isinstance(other, DependencySet):
            depset = other
        else:
            depset = DependencySet(other, set=self.set)

        return C.pkgcraft_dependency_set_is_subset(self.ptr, depset.ptr)

    def issuperset(self, other):
        cdef DependencySet depset = None

        if isinstance(other, DependencySet):
            depset = other
        else:
            depset = DependencySet(other, set=self.set)

        return C.pkgcraft_dependency_set_is_subset(depset.ptr, self.ptr)

    def intersection(self, *others):
        depset = self.clone()

        for obj in others:
            if isinstance(obj, DependencySet):
                depset &= obj
            else:
                depset &= DependencySet(obj, set=self.set)

        return depset

    def union(self, *others):
        depset = self.clone()

        for obj in others:
            if isinstance(obj, DependencySet):
                depset |= obj
            else:
                depset |= DependencySet(obj, set=self.set)

        return depset

    def difference(self, *others):
        depset = self.clone()

        for obj in others:
            if isinstance(obj, DependencySet):
                depset -= obj
            else:
                depset -= DependencySet(obj, set=self.set)

        return depset

    def symmetric_difference(self, *others):
        depset = self.clone()

        for obj in others:
            if isinstance(obj, DependencySet):
                depset ^= obj
            else:
                depset ^= DependencySet(obj, set=self.set)

        return depset

    def __contains__(self, obj):
        if isinstance(obj, Dependency):
            return C.pkgcraft_dependency_set_contains_dependency(self.ptr, (<Dependency>obj).ptr)
        elif isinstance(obj, str):
            return C.pkgcraft_dependency_set_contains_str(self.ptr, obj.encode())
        elif isinstance(obj, UseDep):
            return C.pkgcraft_dependency_set_contains_use_dep(self.ptr, (<UseDep>obj).ptr)
        return False

    def __iter__(self):
        return _IntoIter.from_dependency_set(self.ptr)

    def __reversed__(self):
        return _IntoIterReversed.from_dependency_set(self.ptr)

    def __getitem__(self, key):
        if isinstance(key, int):
            if key < 0:
                key = len(self) + key
            if key < 0 or key >= len(self):
                raise IndexError(f"{self.__class__.__name__} index out of range")
            if ptr := C.pkgcraft_dependency_set_get_index(self.ptr, key):
                return Dependency.from_ptr(ptr)
            raise PkgcraftError  # pragma: no cover
        elif isinstance(key, slice):
            deps = list(self)[key]
            return self.__class__(deps, set=self.set)
        raise TypeError(f"{self.__class__.__name__} indices must be integers or slices")

    def __bool__(self):
        return not C.pkgcraft_dependency_set_is_empty(self.ptr)

    def __len__(self):
        return C.pkgcraft_dependency_set_len(self.ptr)

    def __lt__(self, other):
        if isinstance(other, DependencySet):
            return self <= other and self != other
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, DependencySet):
            return C.pkgcraft_dependency_set_is_subset(self.ptr, (<DependencySet>other).ptr)
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, DependencySet):
            return C.pkgcraft_dependency_set_eq(self.ptr, (<DependencySet>other).ptr)
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, DependencySet):
            return C.pkgcraft_dependency_set_is_subset((<DependencySet>other).ptr, self.ptr)
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, DependencySet):
            return self >= other and self != other
        return NotImplemented

    def __hash__(self):
        return C.pkgcraft_dependency_set_hash(self.ptr)

    def __str__(self):
        return cstring_to_str(C.pkgcraft_dependency_set_str(self.ptr))

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        set = self.set.name
        return f"<{name} {set} '{self}' at 0x{addr:0x}>"

    def __and__(self, other):
        op = C.SetOp.SET_OP_AND
        if isinstance(other, DependencySet):
            obj = <DependencySet>other
            if ptr := C.pkgcraft_dependency_set_op_set(op, self.ptr, obj.ptr):
                return self.create(ptr)
            raise TypeError(f"unsupported DependencySet types: {self.set.name} and {obj.set.name}")
        return NotImplemented

    def __rand__(self, other):
        return self.__and__(other)

    def __or__(self, other):
        op = C.SetOp.SET_OP_OR
        if isinstance(other, DependencySet):
            obj = <DependencySet>other
            if ptr := C.pkgcraft_dependency_set_op_set(op, self.ptr, obj.ptr):
                return self.create(ptr)
            raise TypeError(f"unsupported DependencySet types: {self.set.name} and {obj.set.name}")
        return NotImplemented

    def __ror__(self, other):
        return self.__or__(other)

    def __xor__(self, other):
        op = C.SetOp.SET_OP_XOR
        if isinstance(other, DependencySet):
            obj = <DependencySet>other
            if ptr := C.pkgcraft_dependency_set_op_set(op, self.ptr, obj.ptr):
                return self.create(ptr)
            raise TypeError(f"unsupported DependencySet types: {self.set.name} and {obj.set.name}")
        return NotImplemented

    def __rxor__(self, other):
        return self.__xor__(other)

    def __sub__(self, other):
        op = C.SetOp.SET_OP_SUB
        if isinstance(other, DependencySet):
            obj = <DependencySet>other
            if ptr := C.pkgcraft_dependency_set_op_set(op, self.ptr, obj.ptr):
                return self.create(ptr)
            raise TypeError(f"unsupported DependencySet types: {self.set.name} and {obj.set.name}")
        return NotImplemented

    def __rsub__(self, other):
        return self.__sub__(other)

    def __dealloc__(self):
        C.pkgcraft_dependency_set_free(self.ptr)


@cython.final
cdef class MutableDependencySet(DependencySet):
    """Mutable set of dependency objects."""

    @staticmethod
    cdef MutableDependencySet from_ptr(C.DependencySet *ptr, DependencySet inst = None):
        """Create a MutableDependencySet from a pointer."""
        if inst is None:
            inst = <MutableDependencySet>MutableDependencySet.__new__(MutableDependencySet)
        return DependencySet.from_ptr(ptr, inst)

    def sort(self):
        """Recursively sort a DependencySet.

        >>> from pkgcraft.dep import MutableDependencySet
        >>> d = MutableDependencySet('a/c a/b')
        >>> str(d)
        'a/c a/b'
        >>> d.sort()
        >>> str(d)
        'a/b a/c'

        Dependency objects are ordered by type and recursively sorted if possible.

        >>> d = MutableDependencySet('( a/c a/b ( b/d b/c ) ) || ( a/c a/b ) a/z')
        >>> d.sort()
        >>> str(d)
        'a/z ( a/b a/c ( b/c b/d ) ) || ( a/c a/b )'
        """
        C.pkgcraft_dependency_set_sort(self.ptr)

    def add(self, elem):
        cdef Dependency value

        if isinstance(elem, Dependency):
            value = elem
        else:
            value = Dependency(elem, set=self.set)

        C.pkgcraft_dependency_set_insert(self.ptr, value.ptr)

    def remove(self, elem):
        if isinstance(elem, Dependency):
            obj = elem
        else:
            obj = Dependency(elem, set=self.set)

        if obj in self:
            self.difference_update(obj)
        else:
            raise KeyError(elem)

    def discard(self, elem):
        if elem in self:
            self.difference_update(elem)

    def pop(self):
        if ptr := C.pkgcraft_dependency_set_pop(self.ptr):
            return Dependency.from_ptr(ptr)
        raise KeyError("pop from an empty DependencySet")

    def clear(self):
        if self:
            self.intersection_update([])

    def update(self, *others):
        for obj in others:
            if isinstance(obj, DependencySet):
                self |= obj
            else:
                self |= DependencySet(obj, set=self.set)

        return self

    def intersection_update(self, *others):
        for obj in others:
            if isinstance(obj, DependencySet):
                self &= obj
            else:
                self &= DependencySet(obj, set=self.set)

        return self

    def difference_update(self, *others):
        for obj in others:
            if isinstance(obj, DependencySet):
                self -= obj
            else:
                self -= DependencySet(obj, set=self.set)

        return self

    def symmetric_difference_update(self, *others):
        for obj in others:
            if isinstance(obj, DependencySet):
                self ^= obj
            else:
                self ^= DependencySet(obj, set=self.set)

        return self

    def __iand__(self, other):
        op = C.SetOp.SET_OP_AND
        if isinstance(other, DependencySet):
            obj = <DependencySet>other
            if C.pkgcraft_dependency_set_assign_op_set(op, self.ptr, obj.ptr):
                return self
            raise TypeError(f"unsupported DependencySet types: {self.set.name} and {obj.set.name}")
        return NotImplemented

    def __ior__(self, other):
        op = C.SetOp.SET_OP_OR
        if isinstance(other, DependencySet):
            obj = <DependencySet>other
            if C.pkgcraft_dependency_set_assign_op_set(op, self.ptr, obj.ptr):
                return self
            raise TypeError(f"unsupported DependencySet types: {self.set.name} and {obj.set.name}")
        return NotImplemented

    def __ixor__(self, other):
        op = C.SetOp.SET_OP_XOR
        if isinstance(other, DependencySet):
            obj = <DependencySet>other
            if C.pkgcraft_dependency_set_assign_op_set(op, self.ptr, obj.ptr):
                return self
            raise TypeError(f"unsupported DependencySet types: {self.set.name} and {obj.set.name}")
        return NotImplemented

    def __isub__(self, other):
        op = C.SetOp.SET_OP_SUB
        if isinstance(other, DependencySet):
            obj = <DependencySet>other
            if C.pkgcraft_dependency_set_assign_op_set(op, self.ptr, obj.ptr):
                return self
            raise TypeError(f"unsupported DependencySet types: {self.set.name} and {obj.set.name}")
        return NotImplemented

    def __setitem__(self, key, value not None):
        cdef Dependency dep_key
        cdef Dependency dep_val

        if isinstance(key, int):
            if key < 0:
                key = len(self) + key
            if key < 0 or key >= len(self):
                raise IndexError(f"{self.__class__.__name__} index out of range")

            if isinstance(value, str):
                dep_val = Dependency(value, set=self.set)
            else:
                dep_val = value

            if ptr := C.pkgcraft_dependency_set_replace_index(self.ptr, key, dep_val.ptr):
                C.pkgcraft_dependency_free(ptr)
        elif isinstance(key, (Dependency, str)):
            if isinstance(key, str):
                dep_key = Dependency(key, set=self.set)
            else:
                dep_key = key

            if isinstance(value, str):
                dep_val = Dependency(value, set=self.set)
            else:
                dep_val = value

            if ptr := C.pkgcraft_dependency_set_replace(self.ptr, dep_key.ptr, dep_val.ptr):
                C.pkgcraft_dependency_free(ptr)
        elif isinstance(key, slice):
            deps = list(self)
            deps[key] = iterable_to_dependencies(value, self.set)
            if set_ptr := DependencySet.from_iter(deps, self.set):
                C.pkgcraft_dependency_set_free(self.ptr)
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
    """Iterator over a DependencySet or Dependency object."""

    cdef C.DependencyIntoIter *ptr

    @staticmethod
    cdef _IntoIter from_dependency_set(C.DependencySet *ptr):
        inst = <_IntoIter>_IntoIter.__new__(_IntoIter)
        inst.ptr = C.pkgcraft_dependency_set_into_iter(ptr)
        return inst

    @staticmethod
    cdef _IntoIter from_dependency(C.Dependency *ptr):
        inst = <_IntoIter>_IntoIter.__new__(_IntoIter)
        inst.ptr = C.pkgcraft_dependency_into_iter(ptr)
        return inst

    def __iter__(self):
        return self

    def __next__(self):
        if ptr := C.pkgcraft_dependency_set_into_iter_next(self.ptr):
            return Dependency.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_dependency_set_into_iter_free(self.ptr)


# TODO: re-merge with _IntoIter once @classmethod works with cdef functions for creation
@cython.internal
cdef class _IntoIterReversed(Indirect):
    """Reversed iterator over a DependencySet or Dependency object."""

    cdef C.DependencyIntoIter *ptr

    @staticmethod
    cdef _IntoIterReversed from_dependency_set(C.DependencySet *ptr):
        inst = <_IntoIterReversed>_IntoIterReversed.__new__(_IntoIterReversed)
        inst.ptr = C.pkgcraft_dependency_set_into_iter(ptr)
        return inst

    @staticmethod
    cdef _IntoIterReversed from_dependency(C.Dependency *ptr):
        inst = <_IntoIterReversed>_IntoIterReversed.__new__(_IntoIterReversed)
        inst.ptr = C.pkgcraft_dependency_into_iter(ptr)
        return inst

    def __iter__(self):
        return self

    def __next__(self):
        if ptr := C.pkgcraft_dependency_set_into_iter_next_back(self.ptr):
            return Dependency.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_dependency_set_into_iter_free(self.ptr)


@cython.internal
cdef class _IntoIterConditionals(Indirect):
    """Conditionals iterator over a DependencySet or Dependency object."""

    cdef C.DependencyIntoIterConditionals *ptr

    @staticmethod
    cdef _IntoIterConditionals from_dependency_set(C.DependencySet *ptr):
        inst = <_IntoIterConditionals>_IntoIterConditionals.__new__(_IntoIterConditionals)
        inst.ptr = C.pkgcraft_dependency_set_into_iter_conditionals(ptr)
        return inst

    @staticmethod
    cdef _IntoIterConditionals from_dependency(C.Dependency *ptr):
        inst = <_IntoIterConditionals>_IntoIterConditionals.__new__(_IntoIterConditionals)
        inst.ptr = C.pkgcraft_dependency_into_iter_conditionals(ptr)
        return inst

    def __iter__(self):
        return self

    def __next__(self):
        if ptr := C.pkgcraft_dependency_set_into_iter_conditionals_next(self.ptr):
            return UseDep.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_dependency_set_into_iter_conditionals_free(self.ptr)


@cython.internal
cdef class _IntoIterFlatten(Indirect):
    """Flattened iterator over a DependencySet or Dependency object."""

    cdef C.DependencyIntoIterFlatten *ptr
    cdef C.DependencySetKind set

    @staticmethod
    cdef _IntoIterFlatten from_dependency_set(C.DependencySet *ptr):
        inst = <_IntoIterFlatten>_IntoIterFlatten.__new__(_IntoIterFlatten)
        inst.ptr = C.pkgcraft_dependency_set_into_iter_flatten(ptr)
        inst.set = ptr.set
        return inst

    @staticmethod
    cdef _IntoIterFlatten from_dependency(C.Dependency *ptr):
        inst = <_IntoIterFlatten>_IntoIterFlatten.__new__(_IntoIterFlatten)
        inst.ptr = C.pkgcraft_dependency_into_iter_flatten(ptr)
        inst.set = ptr.set
        return inst

    def __iter__(self):
        return self

    def __next__(self):
        if ptr := C.pkgcraft_dependency_set_into_iter_flatten_next(self.ptr):
            if self.set == C.DEPENDENCY_SET_KIND_PACKAGE:
                return Dep.from_ptr(<C.Dep *>ptr)
            elif self.set == C.DEPENDENCY_SET_KIND_SRC_URI:
                return Uri.from_ptr(<C.Uri *>ptr)
            else:
                return cstring_to_str(<char *>ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_dependency_set_into_iter_flatten_free(self.ptr)


@cython.internal
cdef class _IntoIterRecursive(Indirect):
    """Recursive iterator over a DependencySet or Dependency object."""

    cdef C.DependencyIntoIterRecursive *ptr

    @staticmethod
    cdef _IntoIterRecursive from_dependency_set(C.DependencySet *ptr):
        inst = <_IntoIterRecursive>_IntoIterRecursive.__new__(_IntoIterRecursive)
        inst.ptr = C.pkgcraft_dependency_set_into_iter_recursive(ptr)
        return inst

    @staticmethod
    cdef _IntoIterRecursive from_dependency(C.Dependency *ptr):
        inst = <_IntoIterRecursive>_IntoIterRecursive.__new__(_IntoIterRecursive)
        inst.ptr = C.pkgcraft_dependency_into_iter_recursive(ptr)
        return inst

    def __iter__(self):
        return self

    def __next__(self):
        if ptr := C.pkgcraft_dependency_set_into_iter_recursive_next(self.ptr):
            return Dependency.from_ptr(ptr)
        raise StopIteration

    def __dealloc__(self):
        C.pkgcraft_dependency_set_into_iter_recursive_free(self.ptr)
