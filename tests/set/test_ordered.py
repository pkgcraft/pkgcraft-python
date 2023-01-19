import copy
import gc
import pickle
import weakref

import pytest

from pkgcraft.set import OrderedFrozenSet, OrderedSet


@pytest.fixture
def lst():
    return list(range(10))


class TestOrderedFrozenSet:
    def test_add(self, lst):
        oset = OrderedFrozenSet(lst)
        with pytest.raises(AttributeError):
            oset.add(10)

    def test_discard(self, lst):
        oset = OrderedFrozenSet(lst)
        with pytest.raises(AttributeError):
            oset.discard(0)

    def test_pop(self, lst):
        oset = OrderedFrozenSet(lst)
        with pytest.raises(AttributeError):
            oset.pop()

    def test_remove(self, lst):
        oset = OrderedFrozenSet(lst)
        with pytest.raises(AttributeError):
            oset.remove(0)

    def test_clear(self, lst):
        oset = OrderedFrozenSet(lst)
        with pytest.raises(AttributeError):
            oset.clear()

    def test_difference_update(self):
        # difference_update() isn't available
        oset1 = OrderedFrozenSet([1, 2, 3])
        oset2 = OrderedFrozenSet([3, 4, 5])
        with pytest.raises(AttributeError):
            oset1.difference_update(oset2)

        # __isub__() falls back to __sub__(), replacing the entire set
        orig_id = id(oset1)
        oset1 -= oset2
        assert oset1 == {1, 2}
        assert id(oset1) != orig_id

    def test_intersection_update(self):
        # intersection_update() isn't available
        oset1 = OrderedFrozenSet([1, 2, 3])
        oset2 = OrderedFrozenSet([3, 4, 5])
        with pytest.raises(AttributeError):
            oset1.intersection_update(oset2)

        # __iand__() falls back to __and__(), replacing the entire set
        orig_id = id(oset1)
        oset1 &= oset2
        assert oset1 == {3}
        assert id(oset1) != orig_id

    def test_symmetric_difference_update(self):
        # symmetric_difference_update() isn't available
        oset1 = OrderedFrozenSet([1, 2, 3])
        oset2 = OrderedFrozenSet([3, 4, 5])
        with pytest.raises(AttributeError):
            oset1.symmetric_difference_update(oset2)

        # __ixor__() falls back to __xor_(), replacing the entire set
        orig_id = id(oset1)
        oset1 ^= oset2
        assert oset1 == {1, 2, 4, 5}
        assert id(oset1) != orig_id

    def test_update(self):
        # update() isn't available
        oset1 = OrderedFrozenSet([1, 2, 3])
        oset2 = OrderedFrozenSet([3, 4, 5])
        with pytest.raises(AttributeError):
            oset1.intersection_update(oset2)

        # __ior__() falls back to __or_(), replacing the entire set
        orig_id = id(oset1)
        oset1 |= oset2
        assert oset1 == {1, 2, 3, 4, 5}
        assert id(oset1) != orig_id

    def test_hash(self, lst):
        oset = OrderedFrozenSet(lst)
        assert hash(oset)


class TestOrderedSet:
    def test_add_new(self, lst):
        oset = OrderedSet(lst)

        item = 10
        lst.append(item)
        oset.add(item)

        assert list(oset) == lst

    def test_add_existing(self, lst):
        oset = OrderedSet(lst)

        oset.add(1)
        oset.add(3)
        assert list(oset) == lst

    def test_discard(self):
        oset = OrderedSet([1, 2, 3])

        oset.discard(1)
        assert 1 not in oset

        oset.discard(4)

    def test_pop(self):
        # popping from an empty set raises KeyError
        oset = OrderedSet()
        with pytest.raises(KeyError):
            oset.pop()

        oset = OrderedSet([1, 2, 3])
        v = oset.pop()
        assert v == 3
        v not in oset

        v = oset.pop(last=False)
        assert v == 1
        v not in oset

    def test_remove(self, lst):
        # removing a missing element raises KeyError
        oset = OrderedSet()
        with pytest.raises(KeyError):
            oset.remove(1)

        oset = OrderedSet(lst)
        oset.remove(3)
        lst.remove(3)
        assert list(oset) == lst

    def test_clear(self):
        val = frozenset([1])

        oset = OrderedSet()
        ws = weakref.WeakKeyDictionary()

        oset.add(val)
        ws[val] = 1
        oset.clear()

        assert list(oset) == []

        del val
        gc.collect()
        assert list(ws) == []

    def test_copy(self, lst):
        oset1 = OrderedSet(lst)
        oset2 = oset1.copy()

        assert oset1 is not oset2
        assert oset1 == oset2

        oset1.clear()
        assert oset1 != oset2

    def test_reduce(self, lst):
        oset = OrderedSet(lst)
        oset2 = copy.copy(oset)
        assert oset == oset2

        oset3 = pickle.loads(pickle.dumps(oset))
        assert oset == oset3

        oset.add(-1)
        assert oset != oset2

    def test_difference_and_update(self):
        oset1 = OrderedSet([1, 2, 3])
        oset2 = OrderedSet([3, 4, 5])

        oset3 = oset1 - oset2
        assert oset3 == OrderedSet([1, 2])
        assert oset1 - [3, 4, 5] == oset3

        assert oset1.difference(oset2) == oset3

        oset4 = oset1.copy()
        oset4 -= oset2
        assert oset4 == oset3

        oset5 = oset1.copy()
        oset5.difference_update(oset2)
        assert oset5 == oset3

        oset1 -= oset1
        assert not oset1

        # non-iterable objects raise TypeError
        for (o1, o2) in ((oset1, object()), (object(), oset1)):
            with pytest.raises(TypeError):
                o1 - o2

    def test_intersection_and_update(self):
        oset1 = OrderedSet([1, 2, 3])
        oset2 = OrderedSet([3, 4, 5])

        oset3 = oset1 & oset2
        assert oset3 == OrderedSet([3])
        assert oset1.intersection(oset2) == oset3
        assert oset1 & [3, 4, 5] == oset3

        oset4 = oset1.copy()
        oset4 &= oset2
        assert oset4 == oset3

        oset5 = oset1.copy()
        oset5.intersection_update(oset2)
        assert oset5 == oset3

        oset1 &= oset1
        assert oset1 == oset1

        # non-iterable objects raise TypeError
        for (o1, o2) in ((oset1, object()), (object(), oset1)):
            with pytest.raises(TypeError):
                o1 & o2

    def test_issubset(self):
        oset1 = OrderedSet([1, 2, 3])
        oset2 = OrderedSet([1, 2])

        assert oset2 < oset1
        assert oset2.issubset(oset1)

        oset2 = OrderedSet([1, 2, 3])
        assert oset2 <= oset1
        assert oset1 <= oset2
        assert oset2.issubset(oset1)

        oset2 = OrderedSet([1, 2, 3, 4])
        assert not oset2 < oset1
        assert not oset2.issubset(oset1)
        assert oset1 < oset2

        # issubset compares underordered for all sets
        oset2 = OrderedSet([4, 3, 2, 1])
        assert oset1 < oset2

    def test_issuperset(self):
        oset1 = OrderedSet([1, 2, 3])
        oset2 = OrderedSet([1, 2])

        assert oset1 > oset2
        assert oset1.issuperset(oset2)

        oset2 = OrderedSet([1, 2, 3])
        assert oset1 >= oset2
        assert oset2 >= oset1
        assert oset1.issubset(oset2)

        oset2 = OrderedSet([1, 2, 3, 4])
        assert not oset1 > oset2
        assert not oset1.issuperset(oset2)
        assert oset2 > oset1

        # issubset compares underordered for all sets
        oset2 = OrderedSet([4, 3, 2, 1])
        assert oset2 > oset1

    def test_orderedsubset(self):
        oset1 = OrderedSet([1, 2, 3])
        oset2 = OrderedSet([1, 2, 3, 4])
        oset3 = OrderedSet([1, 2, 4, 3])

        assert oset1.isorderedsubset(oset2)
        assert not oset1.isorderedsubset(oset3)
        assert not oset2.isorderedsubset(oset1)
        assert not oset2.isorderedsubset(oset3)

    def test_orderedsuperset(self):
        oset1 = OrderedSet([1, 2, 3])
        oset2 = OrderedSet([1, 2, 3, 4])
        oset3 = OrderedSet([1, 2, 4, 3])

        assert oset2.isorderedsuperset(oset1)
        assert not oset1.isorderedsuperset(oset3)
        assert not oset3.isorderedsuperset(oset1)
        assert not oset3.isorderedsuperset(oset2)

    def test_symmetric_difference_update(self):
        oset1 = OrderedSet([1, 2, 3])
        oset2 = OrderedSet([2, 3, 4])

        oset3 = oset1 ^ oset2
        assert oset3 == OrderedSet([1, 4])

        oset4 = oset1.copy()
        assert oset4.symmetric_difference(oset2) == oset3

        oset4 ^= oset2
        assert oset4 == oset3

        oset5 = oset1.copy()
        oset5.symmetric_difference_update(oset2)
        assert oset5 == oset3

        oset6 = oset1.copy()
        oset6 ^= [2, 3, 4]
        assert oset6 == oset3

        oset1 ^= oset1
        assert not oset1

        # non-iterable objects raise TypeError
        for (o1, o2) in ((oset1, object()), (object(), oset1)):
            with pytest.raises(TypeError):
                o1 ^ o2

    def test_union_and_update(self, lst):
        oset = OrderedSet(lst)

        oset2 = oset | [3, 9, 27]
        assert oset2 == lst + [27]

        # make sure original oset isn't changed
        assert oset == lst

        oset1 = OrderedSet(lst)
        oset2 = OrderedSet(lst)

        oset3 = oset1 | oset2
        assert oset3 == oset1

        assert oset3 == oset1.union(oset2)

        oset1 |= OrderedSet("abc")
        assert oset1 == oset2 | "abc"

        oset1 = OrderedSet(lst)
        oset1.update("abc")
        assert oset1 == oset2 | "abc"

        # non-iterable objects raise TypeError
        for (o1, o2) in ((oset1, object()), (object(), oset1)):
            with pytest.raises(TypeError):
                o1 | o2

    def test_union_with_iterable(self):
        oset1 = OrderedSet([1])

        assert oset1 | [2, 1] == OrderedSet([1, 2])
        assert [2] | oset1 == OrderedSet([2, 1])
        assert [1, 2] | OrderedSet([3, 1, 2, 4]) == OrderedSet([1, 2, 3, 4])

        # union with unordered set should work, though the order will be arbitrary
        assert oset1 | set([2]) == OrderedSet([1, 2])
        assert set([2]) | oset1 == OrderedSet([2, 1])

    def test_symmetric_difference_with_iterable(self):
        oset1 = OrderedSet([1])

        assert oset1 ^ [1] == OrderedSet([])
        assert [1] ^ oset1 == OrderedSet([])

        assert OrderedSet([3, 1, 4, 2]) ^ [3, 4] == OrderedSet([1, 2])
        assert [3, 1, 4, 2] ^ OrderedSet([3, 4]) == OrderedSet([1, 2])

        assert OrderedSet([3, 1, 4, 2]) ^ set([3, 4]) == OrderedSet([1, 2])
        assert set([3, 1, 4]) ^ OrderedSet([3, 4, 2]) == OrderedSet([1, 2])

    def test_intersection_with_iterable(self):
        assert [1, 2, 3] & OrderedSet([3, 2]) == OrderedSet([2, 3])
        assert OrderedSet([3, 2] & OrderedSet([1, 2, 3])) == OrderedSet([3, 2])

    def test_difference_with_iterable(self):
        assert OrderedSet([1, 2, 3, 4]) - [3, 2] == OrderedSet([1, 4])
        assert [3, 2, 4, 1] - OrderedSet([2, 4]) == OrderedSet([3, 1])

    def test_isdisjoint(self):
        assert OrderedSet().isdisjoint(OrderedSet())
        assert OrderedSet([1]).isdisjoint(OrderedSet([2]))
        assert not OrderedSet([1, 2]).isdisjoint(OrderedSet([2, 3]))

    def test_index(self):
        oset = OrderedSet("abcd")
        assert oset.index("b") == 1

        # nonexistent elements raise ValueError
        with pytest.raises(ValueError):
            oset.index("z")

    def test_getitem(self):
        oset = OrderedSet("abcd")
        assert oset[2] == "c"
        assert oset[-1] == "d"
        assert oset[-2] == "c"

        with pytest.raises(IndexError):
            oset[10]

        # bad indices raise TypeError
        with pytest.raises(TypeError):
            oset["a"]

    def test_getitem_slice(self):
        oset = OrderedSet("abcdef")
        assert oset[:2] == OrderedSet("ab")
        assert oset[2:] == OrderedSet("cdef")
        assert oset[::-1] == OrderedSet("fedcba")
        assert oset[1:-1:2] == OrderedSet("bd")
        assert oset[1::2] == OrderedSet("bdf")

    def test_len(self, lst):
        oset = OrderedSet(lst)
        assert len(oset) == len(lst)

        oset.remove(0)
        assert len(oset) == len(lst) - 1

    def test_contains(self, lst):
        oset = OrderedSet(lst)
        assert 1 in oset

    def test_iter_mutated(self, lst):
        oset = OrderedSet(lst)
        it = iter(oset)
        assert it is iter(it)
        oset.add("a")

        with pytest.raises(RuntimeError):
            next(it)

        it = reversed(oset)
        oset.add("b")

        with pytest.raises(RuntimeError):
            next(it)

    def test_iter_and_valid_order(self, lst):
        oset = OrderedSet(lst)
        assert list(oset) == lst

        oset = OrderedSet(lst + lst)
        assert list(oset) == lst

    def test_reverse_order(self, lst):
        oset = OrderedSet(lst)
        assert list(reversed(oset)) == list(reversed(lst))

    def test_repr(self):
        oset = OrderedSet([1])
        assert repr(oset) == "OrderedSet([1])"
        oset = OrderedSet()
        assert repr(oset) == "OrderedSet()"

    def test_eq(self, lst):
        oset1 = OrderedSet(lst)
        oset2 = OrderedSet(lst)

        assert oset1 is not None

        assert oset1 == oset2
        assert oset1 == set(lst)
        assert oset1 == list(lst)

    def test_ordering(self, lst):
        oset1 = OrderedSet(lst)
        oset2 = OrderedSet(lst)

        assert oset2 <= oset1
        assert oset2 <= set(oset1)
        assert oset2 <= list(oset1)
        with pytest.raises(TypeError):
            oset2 <= object()

        assert oset1 >= oset2
        assert oset1 >= set(oset2)
        assert oset1 >= list(oset2)
        with pytest.raises(TypeError):
            oset1 >= object()

        oset3 = OrderedSet(lst[:-1])

        assert oset3 < oset1
        assert oset3 < set(oset1)
        assert oset3 < list(oset1)
        with pytest.raises(TypeError):
            oset3 < object()

        assert oset1 > oset3
        assert oset1 > set(oset3)
        assert oset1 > list(oset3)
        with pytest.raises(TypeError):
            oset1 > object()

    def test_hash(self, lst):
        oset = OrderedSet(lst)
        with pytest.raises(TypeError):
            assert hash(oset)
