cimport cython


cdef class entry:
    cdef object key
    cdef entry prev
    cdef entry next


cdef class OrderedFrozenSet:
    cdef dict map
    cdef entry end
    cdef ssize_t os_used

    cdef _getslice(self, slice item)
    cdef _getindex(self, ssize_t index)


cdef class OrderedSet(OrderedFrozenSet):
    cpdef add(self, elem)
    cpdef discard(self, elem)
    cpdef pop(self, bint last=*)
