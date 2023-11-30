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

    cpdef bint isorderedsubset(self, OrderedFrozenSet)
    cpdef bint isorderedsuperset(self, OrderedFrozenSet)


cdef class OrderedSet(OrderedFrozenSet):
    cpdef void add(self, object)
    cpdef void discard(self, object)
    cpdef object pop(self, bint last=*)
