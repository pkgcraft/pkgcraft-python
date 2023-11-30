from collections.abc import Iterable, MutableSet, Set

cimport cython
from cpython cimport PyIndex_Check
from cpython.slice cimport PySlice_GetIndicesEx


@cython.internal
cdef class OrderedSetIterator:
    cdef OrderedFrozenSet oset
    cdef entry curr
    cdef ssize_t si_used

    def __cinit__(self, OrderedFrozenSet oset):
        self.oset = oset
        self.curr = oset.end
        self.si_used = oset.os_used

    def __iter__(self):
        return self

    def __next__(self):
        cdef entry item

        if self.si_used != self.oset.os_used:
            # make this state sticky
            self.si_used = -1
            set_type = self.oset.__class__.__name__
            raise RuntimeError(f'{set_type} changed size during iteration')

        item = self.curr.next
        if item == self.oset.end:
            raise StopIteration
        self.curr = item
        return item.key


@cython.internal
cdef class OrderedSetReverseIterator:
    cdef OrderedFrozenSet oset
    cdef entry curr
    cdef ssize_t si_used

    def __cinit__(self, OrderedFrozenSet oset):
        self.oset = oset
        self.curr = oset.end
        self.si_used = oset.os_used

    def __iter__(self):
        return self

    def __next__(self):
        cdef entry item

        if self.si_used != self.oset.os_used:
            # make this state sticky
            self.si_used = -1
            set_type = self.oset.__class__.__name__
            raise RuntimeError(f'{set_type} changed size during iteration')

        item = self.curr.prev
        if item is self.oset.end:
            raise StopIteration
        self.curr = item
        return item.key


cdef class OrderedFrozenSet:
    """
    An ``OrderedFrozenSet`` object is an immutable, ordered collection of distinct hashable objects.

    It works like the :class:`set` type, but remembers insertion order.

    It also supports :meth:`__getitem__` and :meth:`index`, like the
    :class:`list` type.
    """
    def __cinit__(self):
        self.map = {}
        self.os_used = 0
        self.end = end = entry()
        end.prev = end.next = end

    def __init__(self, object iterable=None):
        cdef entry next

        if iterable is not None:
            for elem in iterable:
                if elem not in self.map:
                    next = entry()
                    next.key, next.prev, next.next = elem, self.end.prev, self.end
                    self.end.prev.next = self.end.prev = self.map[elem] = next
                    self.os_used += 1

    @classmethod
    def _from_iterable(cls, it):
        return cls(it)

    ##
    # immutable set methods
    ##
    def copy(self):
        """
        :rtype: OrderedSet
        :return: a new ``OrderedSet`` with a shallow copy of self.
        """
        return self._from_iterable(self)

    def difference(self, other):
        """``OrderedSet - other``

        :rtype: OrderedSet
        :return: a new ``OrderedSet`` with elements in the set that are not in the others.
        """
        return self - other

    def __sub__(self, other):
        """
        :rtype: OrderedSet
        """
        if isinstance(other, Iterable):
            if not isinstance(other, Set):
                other = set(other)
            return self.__class__._from_iterable(value for value in self if value not in other)
        return NotImplemented

    def intersection(self, other):
        """``OrderedSet & other``

        :rtype: OrderedSet
        :return: a new ``OrderedSet`` with elements common to the set and all others.
        """
        return self & other

    def __and__(self, other):
        """
        :rtype: OrderedSet
        """
        if isinstance(other, Iterable):
            if not isinstance(other, Set):
                other = set(other)
            return self.__class__._from_iterable(value for value in self if value in other)
        return NotImplemented

    def __rand__(self, other):
        return self.__and__(other)

    def isdisjoint(self, other):
        """
        Return True if the set has no elements in common with other.
        Sets are disjoint if and only if their intersection is the empty set.

        :rtype: bool
        """
        for value in other:
            if value in self:
                return False
        return True

    def issubset(self, other):
        """``OrderedSet <= other``

        :rtype: bool

        Test whether the ``OrderedSet`` is a proper subset of other, that is,
        ``OrderedSet <= other and OrderedSet != other``.
        """
        return self <= other

    def issuperset(self, other):
        """``OrderedSet >= other``

        :rtype: bool

        Test whether every element in other is in the set.
        """
        return other <= self

    cpdef bint isorderedsubset(self, OrderedFrozenSet other):
        if len(self) > len(other):
            return False
        for self_elem, other_elem in zip(self, other):
            if not self_elem == other_elem:
                return False
        return True

    cpdef bint isorderedsuperset(self, OrderedFrozenSet other):
        return other.isorderedsubset(self)

    def symmetric_difference(self, other):
        """``OrderedSet ^ other``

        :rtype: OrderedSet
        :return: a new ``OrderedSet`` with elements in either the set or other but not both.
        """
        return self ^ other

    def __xor__(self, other):
        """
        :rtype: OrderedSet
        """
        return (self - other) | (other - self)

    def __rxor__(self, other):
        return self.__xor__(other)

    def union(self, other):
        """``OrderedSet | other``

        :rtype: OrderedSet
        :return: a new ``OrderedSet`` with elements from the set and all others.
        """
        return self | other

    def __or__(self, other):
        """
        :rtype: OrderedSet
        """
        if isinstance(other, Iterable):
            chain = (e for s in (self, other) for e in s)
            return self.__class__._from_iterable(chain)
        return NotImplemented

    def __ror__(self, other):
        return self.__or__(other)

    ##
    # list methods
    ##
    def index(self, elem):
        """Return the index of `elem`.
        Raises :class:`ValueError` if not in the set.
        """
        if elem not in self:
            set_type = self.__class__.__name__
            raise ValueError(f'{elem} is not in {set_type}')
        cdef entry curr = self.end.next
        cdef ssize_t index = 0
        while curr.key != elem:
            curr = curr.next
            index += 1
        return index

    cdef _getslice(self, slice item):
        cdef ssize_t start, stop, step, slicelength, place, i
        cdef entry curr
        cdef OrderedSet result
        PySlice_GetIndicesEx(item, len(self), &start, &stop, &step, &slicelength)

        result = self.__class__()
        place = start
        curr = self.end

        if slicelength <= 0:
            pass
        elif step > 0:
            # normal forward slice
            i = 0
            while slicelength > 0:
                while i <= place:
                    curr = curr.next
                    i += 1
                result.add(curr.key)
                place += step
                slicelength -= 1
        else:
            # we're going backwards
            i = len(self)
            while slicelength > 0:
                while i > place:
                    curr = curr.prev
                    i -= 1
                result.add(curr.key)
                place += step
                slicelength -= 1
        return result

    cdef _getindex(self, ssize_t index):
        cdef ssize_t _len = len(self)
        if index >= _len or (index < 0 and abs(index) > _len):
            raise IndexError("list index out of range")

        cdef entry curr
        if index >= 0:
            curr = self.end.next
            while index:
                curr = curr.next
                index -= 1
        else:
            index = abs(index) - 1
            curr = self.end.prev
            while index:
                curr = curr.prev
                index -= 1
        return curr.key

    def __getitem__(self, item):
        """Return the `elem` at `index`.
        Raises :class:`IndexError` if `index` is out of range.
        """
        if isinstance(item, slice):
            return self._getslice(item)
        if not PyIndex_Check(item):
            set_type, item_type = self.__class__.__name__, item.__class__.__name__
            raise TypeError(f'{set_type} indices must be integers, not {item_type}')
        return self._getindex(item)

    ##
    # sequence methods
    ##
    def __len__(self):
        return len(self.map)

    def __contains__(self, elem):
        return elem in self.map

    def __iter__(self):
        return OrderedSetIterator(self)

    def __reversed__(self):
        return OrderedSetReverseIterator(self)

    def __repr__(self):
        if not self:
            return '%s()' % (self.__class__.__name__,)
        return '%s(%r)' % (self.__class__.__name__, list(self))

    def __eq__(self, other):
        if isinstance(other, (OrderedFrozenSet, list)):
            return len(self) == len(other) and list(self) == list(other)
        elif isinstance(other, Set):
            return set(self) == set(other)
        return NotImplemented

    def __le__(self, other):
        if isinstance(other, Set):
            return len(self) <= len(other) and set(self) <= set(other)
        elif isinstance(other, list):
            return len(self) <= len(other) and list(self) <= list(other)
        return NotImplemented

    def __lt__(self, other):
        if isinstance(other, Set):
            return len(self) < len(other) and set(self) < set(other)
        elif isinstance(other, list):
            return len(self) < len(other) and list(self) < list(other)
        return NotImplemented

    def __ge__(self, other):
        if isinstance(other, Set):
            return len(self) >= len(other) and set(self) >= set(other)
        elif isinstance(other, list):
            return len(self) >= len(other) and list(self) >= list(other)
        return NotImplemented

    def __gt__(self, other):
        if isinstance(other, Set):
            return len(self) > len(other) and set(self) > set(other)
        elif isinstance(other, list):
            return len(self) > len(other) and list(self) > list(other)
        return NotImplemented

    def __hash__(self):
        return hash(tuple(self.map))

    def __copy__(self):
        return self._from_iterable(self)

    def __reduce__(self):
        return self.__class__, (list(self),)


cdef class OrderedSet(OrderedFrozenSet):
    """
    An ``OrderedSet`` object is a mutable, ordered collection of distinct hashable objects.

    It works like the :class:`set` type, but remembers insertion order.

    It also supports :meth:`__getitem__` and :meth:`index`, like the
    :class:`list` type.
    """
    ##
    # mutable set methods
    ##
    cpdef void add(self, object elem):
        """Add element `elem` to the set."""
        cdef entry next

        if elem not in self.map:
            next = entry()
            next.key, next.prev, next.next = elem, self.end.prev, self.end
            self.end.prev.next = self.end.prev = self.map[elem] = next
            self.os_used += 1

    cpdef void discard(self, object elem):
        """Remove element `elem` from the ``OrderedSet`` if it is present."""
        cdef entry _entry

        if elem in self.map:
            _entry = self.map.pop(elem)
            _entry.prev.next = _entry.next
            _entry.next.prev = _entry.prev
            self.os_used -= 1

    cpdef object pop(self, bint last=True):
        """Remove last element. Raises ``KeyError`` if the ``OrderedSet`` is empty."""
        if not self:
            set_type = self.__class__.__name__
            raise KeyError(f'{set_type} is empty')
        key = self.end.prev.key if last else self.end.next.key
        self.discard(key)
        return key

    def remove(self, elem):
        """
        Remove element `elem` from the ``set``.
        Raises :class:`KeyError` if `elem` is not contained in the set.
        """
        if elem not in self:
            raise KeyError(elem)
        self.discard(elem)

    def clear(self):
        """Remove all elements from the `set`."""
        cdef entry end = self.end
        end.next.prev = end.next = None

        # reinitialize
        self.map = {}
        self.os_used = 0
        self.end = end = entry()
        end.prev = end.next = end

    def difference_update(self, other):
        """``OrderedSet -= other``

        Update the ``OrderedSet``, removing elements found in others.
        """
        self -= other

    def __isub__(self, other):
        if other is self:
            self.clear()
        else:
            for value in other:
                self.discard(value)
        return self

    def intersection_update(self, other):
        """``OrderedSet &= other``

        Update the ``OrderedSet``, keeping only elements found in it and all others.
        """
        self &= other

    def __iand__(self, it):
        for value in (self - it):
            self.discard(value)
        return self

    def symmetric_difference_update(self, other):
        """``OrderedSet ^= other``

        Update the ``OrderedSet``, keeping only elements found in either set, but not in both.
        """
        self ^= other

    def __ixor__(self, other):
        if other is self:
            self.clear()
        else:
            if not isinstance(other, Set):
                other = set(other)
            for value in other:
                if value in self:
                    self.discard(value)
                else:
                    self.add(value)
        return self

    def update(self, other):
        """``OrderedSet |= other``

        Update the ``OrderedSet``, adding elements from all others.
        """
        self |= other

    def __ior__(self, other):
        for elem in other:
            self.add(elem)
        return self

    # Override parent class to implicitly set __hash__ to None so hashing
    # raises TypeError and instances are correctly identified as unhashable
    # using `isinstance(obj, collections.abc.Hashable)`.
    def __eq__(self, other):
        return super().__eq__(other)


# register classes for isinstance() and issubclass() usage
Set.register(OrderedFrozenSet)
MutableSet.register(OrderedSet)
