from enum import IntEnum

cimport cython

from ... cimport C
from ..._misc cimport cstring_to_str

from ...error import PkgcraftError


class KeywordStatus(IntEnum):
    Disabled = C.KEYWORD_STATUS_DISABLED
    Unstable = C.KEYWORD_STATUS_UNSTABLE
    Stable = C.KEYWORD_STATUS_STABLE


@cython.final
cdef class Keyword:
    """Ebuild package keyword."""

    def __init__(self, s: str):
        """Create a new package keyword.

        Args:
            s: the string to parse

        Returns:
            Keyword: the created package keyword instance

        Raises:
            PkgcraftError: on parsing failure
        """
        ptr = C.pkgcraft_keyword_new(s.encode())
        if ptr is NULL:
            raise PkgcraftError

        Keyword.from_ptr(ptr, self)

    @staticmethod
    cdef Keyword from_ptr(C.Keyword *ptr, Keyword inst = None):
        """Create a Keyword from a pointer."""
        if inst is None:
            inst = <Keyword>Keyword.__new__(Keyword)
        inst.status = KeywordStatus(ptr.status)
        inst.arch = ptr.arch.decode()
        inst.ptr = ptr
        return inst

    def __lt__(self, other):
        if isinstance(other, Keyword):
            return C.pkgcraft_keyword_cmp(self.ptr, (<Keyword>other).ptr) == -1
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, Keyword):
            return C.pkgcraft_keyword_cmp(self.ptr, (<Keyword>other).ptr) <= 0
        return NotImplemented

    def __eq__(self, other):
        if isinstance(other, Keyword):
            return C.pkgcraft_keyword_cmp(self.ptr, (<Keyword>other).ptr) == 0
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, Keyword):
            return C.pkgcraft_keyword_cmp(self.ptr, (<Keyword>other).ptr) != 0
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, Keyword):
            return C.pkgcraft_keyword_cmp(self.ptr, (<Keyword>other).ptr) >= 0
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, Keyword):
            return C.pkgcraft_keyword_cmp(self.ptr, (<Keyword>other).ptr) == 1
        return NotImplemented

    def __hash__(self):
        if not self._hash:
            self._hash = C.pkgcraft_keyword_hash(self.ptr)
        return self._hash

    def __str__(self):
        return cstring_to_str(C.pkgcraft_keyword_str(self.ptr))

    def __repr__(self):
        addr = <size_t>&self.ptr
        name = self.__class__.__name__
        return f"<{name} '{self}' at 0x{addr:0x}>"

    def __dealloc__(self):
        C.pkgcraft_keyword_free(self.ptr)
