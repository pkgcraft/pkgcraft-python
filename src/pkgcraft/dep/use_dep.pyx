from enum import IntEnum

from .. cimport C
from .._misc cimport cstring_to_str

from ..error import PkgcraftError


class UseDepKind(IntEnum):
    Enabled = C.USE_DEP_KIND_ENABLED
    Disabled = C.USE_DEP_KIND_DISABLED
    Equal = C.USE_DEP_KIND_EQUAL
    NotEqual = C.USE_DEP_KIND_NOT_EQUAL
    EnabledConditional = C.USE_DEP_KIND_ENABLED_CONDITIONAL
    DisabledConditional = C.USE_DEP_KIND_DISABLED_CONDITIONAL


class UseDepDefault(IntEnum):
    Enabled = C.USE_DEP_DEFAULT_ENABLED
    Disabled = C.USE_DEP_DEFAULT_DISABLED


cdef class UseDep:
    """Package USE dependency."""

    def __init__(self, s: str):
        """Create a new package USE dependency.

        Args:
            s: the USE string to parse

        Returns:
            UseDep: the created package USE dependency instance

        Raises:
            PkgcraftError: on parsing failure

        Valid

        >>> from pkgcraft.dep import UseDep
        >>> u = UseDep('!use?')
        >>> u.flag
        'use'
        >>> u.kind == UseDepKind.DisabledConditional
        True
        >>> u.default is None
        True
        >>> str(u)
        '!use?'
        >>> u = UseDep('use(+)=')
        >>> u.flag
        'use'
        >>> u.kind == UseDepKind.Equal
        True
        >>> u.default == UseDepDefault.Enabled
        True
        >>> str(u)
        'use(+)='

        Invalid

        >>> UseDep('+')
        Traceback (most recent call last):
            ...
        pkgcraft.error.PkgcraftError: parsing failure: invalid use dep: +
        ...
        """
        ptr = C.pkgcraft_use_dep_new(s.encode())
        if ptr is NULL:
            raise PkgcraftError

        UseDep.from_ptr(ptr, self)

    @staticmethod
    cdef UseDep from_ptr(C.UseDep *ptr, UseDep inst = None):
        """Create a UseDep from a pointer."""
        if inst is None:
            inst = <UseDep>UseDep.__new__(UseDep)
        inst.ptr = <C.UseDep *>ptr
        inst.kind = UseDepKind(ptr.kind)
        inst.flag = ptr.flag.decode()
        if ptr.default_ is NULL:
            inst.default_ = None
        else:
            inst.default_ = UseDepDefault(ptr.default_[0])
        return inst

    # Re-export the default field using its proper name, if exposed directly via
    # an attribute the bindings fail to compile.
    @property
    def default(self):
        return self.default_

    def __lt__(self, other):
        if isinstance(other, UseDep):
            return C.pkgcraft_use_dep_cmp(self.ptr, (<UseDep>other).ptr) == -1
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, UseDep):
            return C.pkgcraft_use_dep_cmp(self.ptr, (<UseDep>other).ptr) <= 0
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, UseDep):
            return C.pkgcraft_use_dep_cmp(self.ptr, (<UseDep>other).ptr) == 0
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, UseDep):
            return C.pkgcraft_use_dep_cmp(self.ptr, (<UseDep>other).ptr) != 0
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, UseDep):
            return C.pkgcraft_use_dep_cmp(self.ptr, (<UseDep>other).ptr) >= 0
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, UseDep):
            return C.pkgcraft_use_dep_cmp(self.ptr, (<UseDep>other).ptr) == 1
        return NotImplemented

    def __hash__(self):
        if not self._hash:
            self._hash = C.pkgcraft_use_dep_hash(self.ptr)
        return self._hash

    def __str__(self):
        return cstring_to_str(C.pkgcraft_use_dep_str(self.ptr))

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        kind = self.kind.name
        return f"<{name} {kind} '{self}' at 0x{addr:0x}>"

    def __dealloc__(self):
        C.pkgcraft_use_dep_free(self.ptr)
