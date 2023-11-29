from .. cimport C
from ..types cimport OrderedFrozenSet


cdef class RepoSet:
    cdef C.RepoSet *ptr

    # cached fields
    cdef OrderedFrozenSet _repos

    @staticmethod
    cdef RepoSet from_ptr(C.RepoSet *)

    cdef create(self, C.RepoSet *)


cdef class MutableRepoSet(RepoSet):

    @staticmethod
    cdef MutableRepoSet from_ptr(C.RepoSet *)
