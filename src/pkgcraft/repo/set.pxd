from .. cimport C


cdef class RepoSet:
    cdef C.RepoSet *ptr

    # cached fields
    cdef object _repos

    @staticmethod
    cdef RepoSet from_ptr(C.RepoSet *)

    cdef create(self, C.RepoSet *)


cdef class MutableRepoSet(RepoSet):

    @staticmethod
    cdef MutableRepoSet from_ptr(C.RepoSet *)
