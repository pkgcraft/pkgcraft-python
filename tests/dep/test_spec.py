from functools import partial

import pytest

from pkgcraft.dep import *
from pkgcraft.eapi import EAPI_LATEST, EAPI_LATEST_OFFICIAL
from pkgcraft.error import PkgcraftError

from ..misc import OperatorMap


class TestDepSpec:
    req_use = partial(DepSpec, set=DepSetKind.RequiredUse)

    def test_creation(self):
        # empty strings fail
        with pytest.raises(PkgcraftError):
            DepSpec("")

        # multiple DepSpecs fail
        with pytest.raises(PkgcraftError):
            DepSpec("a/b c/d")

        # variants
        d = self.req_use("a")
        assert len(d) == 1
        assert str(d) == "a"
        assert "Enabled 'a' at 0x" in repr(d)
        # EAPI specific
        assert d == self.req_use("a", eapi=str(EAPI_LATEST_OFFICIAL))
        assert d == self.req_use("a", eapi=EAPI_LATEST_OFFICIAL)

        d = self.req_use("!a")
        assert len(d) == 1
        assert str(d) == "!a"
        assert "Disabled '!a' at 0x" in repr(d)

        d = self.req_use("( a b )")
        assert len(d) == 2
        assert str(d) == "( a b )"
        assert "AllOf '( a b )' at 0x" in repr(d)

        d = self.req_use("|| ( a b )")
        assert len(d) == 2
        assert str(d) == "|| ( a b )"
        assert "AnyOf '|| ( a b )' at 0x" in repr(d)

        d = self.req_use("^^ ( a b )")
        assert len(d) == 2
        assert str(d) == "^^ ( a b )"
        assert "ExactlyOneOf '^^ ( a b )' at 0x" in repr(d)

        d = self.req_use("?? ( a b )")
        assert len(d) == 2
        assert str(d) == "?? ( a b )"
        assert "AtMostOneOf '?? ( a b )' at 0x" in repr(d)

        d = self.req_use("u? ( a )")
        assert len(d) == 1
        assert str(d) == "u? ( a )"
        assert "UseEnabled 'u? ( a )' at 0x" in repr(d)

        d = self.req_use("!u1? ( a u2? ( b ) )")
        assert len(d) == 2
        assert str(d) == "!u1? ( a u2? ( b ) )"
        assert "UseDisabled '!u1? ( a u2? ( b ) )' at 0x" in repr(d)

        # raw Deps
        d = DepSpec(Dep("a/b"))
        assert len(d) == 1
        assert str(d) == "a/b"
        assert "Enabled 'a/b' at 0x" in repr(d)

        # invalid args
        for obj in [None, object()]:
            with pytest.raises(TypeError):
                DepSpec(obj)

    def test_cmp(self):
        for set1, set2 in (
            (DepSetKind.RequiredUse, DepSetKind.RequiredUse),
            (DepSetKind.RequiredUse, DepSetKind.License),
        ):
            for s1, op, s2 in (
                ("a", "<", "b"),
                ("a", "<=", "b"),
                ("b", "<=", "b"),
                ("b", "==", "b"),
                ("b", "!=", "a"),
                ("b", ">=", "b"),
                ("b", ">", "a"),
            ):
                op_func = OperatorMap[op]
                d1 = DepSpec(s1, set=set1)
                d2 = DepSpec(s2, set=set2)
                assert op_func(d1, d2), f"failed {d1} {op} {d2}"

        # verify incompatible type comparisons
        obj = self.req_use("a")
        for op, op_func in OperatorMap.items():
            if op == "==":
                assert not op_func(obj, None)
            elif op == "!=":
                assert op_func(obj, None)
            else:
                with pytest.raises(TypeError):
                    op_func(obj, None)

    def test_eq_and_hash(self):
        # ordering that doesn't matter for equivalence and hashing
        for s1, s2 in (
            # same
            ("a", "a"),
            ("u? ( a )", "u? ( a )"),
            ("u? ( a || ( a b ) )", "u? ( a || ( a b ) )"),
            # different order, but equivalent
            ("( a b )", "( b a )"),
            ("u? ( a b )", "u? ( b a )"),
            ("!u? ( a b )", "!u? ( b a )"),
            ("|| ( a u? ( c b ) )", "|| ( a u? ( b c ) )"),
        ):
            d1 = self.req_use(s1)
            d2 = self.req_use(s2)
            assert d1 == d2
            assert len({d1, d2}) == 1

        # ordering that matters for equivalence and hashing
        for s1, s2 in (
            ("|| ( a b )", "|| ( b a )"),
            ("?? ( a b )", "?? ( b a )"),
            ("^^ ( a b )", "^^ ( b a )"),
            ("u? ( a || ( c b ) )", "u? ( a || ( b c ) )"),
        ):
            d1 = self.req_use(s1)
            d2 = self.req_use(s2)
            assert d1 != d2
            assert len({d1, d2}) == 2

    def test_contains(self):
        # simple DepSpecs don't contain themselves
        assert self.req_use("a") not in self.req_use("a")

        # only top-level DepSpec objects have membership
        d = self.req_use("!u1? ( a u2? ( b ) )")
        assert self.req_use("a") in d
        assert self.req_use("u2? ( b )") in d
        assert self.req_use("b") not in d

        # non-DepSpec objects return False
        assert None not in d

    def test_iter(self):
        assert list(self.req_use("a")) == []
        assert list(iter(self.req_use("!a"))) == []
        assert list(map(str, self.req_use("( a )"))) == ["a"]
        assert list(map(str, self.req_use("|| ( a b )"))) == ["a", "b"]
        assert list(map(str, self.req_use("|| ( u? ( a ) )"))) == ["u? ( a )"]

    def test_reversed(self):
        assert list(reversed(self.req_use("a"))) == []
        assert list(reversed(self.req_use("!a"))) == []
        assert list(map(str, reversed(self.req_use("( a )")))) == ["a"]
        assert list(map(str, reversed(self.req_use("|| ( a b )")))) == ["b", "a"]
        assert list(map(str, reversed(self.req_use("|| ( u? ( a ) )")))) == ["u? ( a )"]

    def test_iter_conditionals(self):
        assert list(self.req_use("a").iter_conditionals()) == []
        assert list(self.req_use("( a )").iter_conditionals()) == []
        assert list(self.req_use("u? ( a )").iter_conditionals()) == ["u"]
        assert list(self.req_use("!u? ( a )").iter_conditionals()) == ["u"]
        assert list(self.req_use("|| ( u1? ( b !u2? ( d ) ) )").iter_conditionals()) == ["u1", "u2"]

    def test_iter_flatten(self):
        assert list(self.req_use("a").iter_flatten()) == ["a"]
        assert list(self.req_use("!a").iter_flatten()) == ["a"]
        assert list(self.req_use("( a )").iter_flatten()) == ["a"]
        assert list(self.req_use("|| ( a b )").iter_flatten()) == ["a", "b"]
        assert list(self.req_use("|| ( u? ( a ) )").iter_flatten()) == ["a"]

    def test_iter_recursive(self):
        assert list(map(str, self.req_use("a").iter_recursive())) == ["a"]
        assert list(map(str, self.req_use("!a").iter_recursive())) == ["!a"]
        assert list(map(str, self.req_use("( a )").iter_recursive())) == ["( a )", "a"]
        assert list(map(str, self.req_use("|| ( a b )").iter_recursive())) == [
            "|| ( a b )",
            "a",
            "b",
        ]
        assert list(map(str, self.req_use("|| ( u? ( a ) )").iter_recursive())) == [
            "|| ( u? ( a ) )",
            "u? ( a )",
            "a",
        ]

    def test_evaluate(self):
        d = self.req_use("a")

        # no conditionals
        assert d.evaluate() == [d]
        assert d.evaluate(["u"]) == [d]
        assert d.evaluate(True) == [d]
        assert d.evaluate(False) == [d]

        # conditionally enabled
        d1 = self.req_use("u? ( a )")
        assert d1.evaluate() == []
        assert d1.evaluate(["u"]) == [d]
        assert d1.evaluate(True) == [d]
        assert d1.evaluate(False) == []
        d1 = self.req_use("u? ( a b )")
        assert d1.evaluate(["u"]) == [self.req_use("a"), self.req_use("b")]

        # conditionally disabled
        d1 = self.req_use("!u? ( a )")
        assert d1.evaluate() == [d]
        assert d1.evaluate(["u"]) == []
        assert d1.evaluate(True) == [d]
        assert d1.evaluate(False) == []

        # empty DepSpecs are discarded
        d1 = self.req_use("|| ( u1? ( a !u2? ( b ) ) )")
        assert not d1.evaluate()
        assert d1.evaluate(["u1"]) == [self.req_use("|| ( a b )")]
        assert d1.evaluate(["u1", "u2"]) == [self.req_use("|| ( a )")]
        assert d1.evaluate(["u2"]) == []
        assert d1.evaluate(True) == [self.req_use("|| ( a b )")]
        assert not d1.evaluate(False)


class DepSetBase:
    def test_creation(self):
        # empty DepSets
        d = self.cls()
        assert d == self.cls("")
        assert not d
        assert len(d) == 0
        assert str(d) == ""
        assert "Dependencies '' at 0x" in repr(d)

        dep1 = DepSpec("a/b")
        dep2 = DepSpec("u? ( c/d )")

        # DepSpec arg
        d = self.cls(dep1)
        assert d == self.cls("a/b")
        assert d
        assert len(d) == 1
        assert str(d) == "a/b"
        assert "Dependencies 'a/b' at 0x" in repr(d)

        # iterable of DepSpecs
        d = self.cls([dep1, dep2])
        assert d == self.cls("a/b u? ( c/d )")
        assert d
        assert len(d) == 2
        assert str(d) == "a/b u? ( c/d )"
        assert "Dependencies 'a/b u? ( c/d )' at 0x" in repr(d)

        # iterable of DepSpec strings
        d = self.cls(["a/b", "|| ( c/d e/f )"])
        assert d == self.cls("a/b || ( c/d e/f )")
        assert d
        assert len(d) == 2
        assert str(d) == "a/b || ( c/d e/f )"
        assert "Dependencies 'a/b || ( c/d e/f )' at 0x" in repr(d)

        # empty iterables
        assert self.cls([]) == self.cls(self.cls())

        # DepSet iterables
        d1 = self.cls("a/b c/d")
        d2 = self.cls(d1)
        assert d2 == d1
        assert d2 == self.cls(list(d2))

        # re-creation creates a clone
        d1 = self.cls("a/b")
        d2 = self.cls(d1)
        assert d1 == d2 and d1 is not d2

        # EAPI kwargs
        d1 = self.cls("a/b", eapi=EAPI_LATEST_OFFICIAL)
        d2 = self.cls("a/b", eapi=str(EAPI_LATEST_OFFICIAL))
        assert d1 == d2
        d3 = self.cls("a/b::repo", eapi=EAPI_LATEST)
        assert d1 != d3

        # kwargs
        for s, kind in [
            ("a/b", DepSetKind.Dependencies),
            ("a", DepSetKind.License),
            ("a", DepSetKind.Properties),
            ("a", DepSetKind.RequiredUse),
            ("a", DepSetKind.Restrict),
            ("a", DepSetKind.SrcUri),
        ]:
            d = self.cls(s, set=kind)
            assert len(d) == 1

        # invalid
        with pytest.raises(PkgcraftError):
            self.cls("a")
        with pytest.raises(PkgcraftError):
            self.cls("a/b::repo", EAPI_LATEST_OFFICIAL)

        # invalid args
        for obj in [0, object()]:
            with pytest.raises(TypeError):
                self.cls(obj)

    def test_iter(self):
        assert list(self.cls()) == []
        assert list(iter(self.cls("a/b"))) == [DepSpec("a/b")]
        assert list(self.cls("( a/b )")) == [DepSpec("( a/b )")]
        assert list(self.cls("a/b || ( c/d e/f )")) == [DepSpec("a/b"), DepSpec("|| ( c/d e/f )")]
        assert list(self.cls("|| ( u? ( a/b ) )")) == [DepSpec("|| ( u? ( a/b ) )")]

    def test_reversed(self):
        assert list(reversed(self.cls())) == []
        assert list(reversed(self.cls("a/b"))) == [DepSpec("a/b")]
        assert list(reversed(self.cls("( a/b )"))) == [DepSpec("( a/b )")]
        assert list(reversed(self.cls("a/b || ( c/d e/f )"))) == [
            DepSpec("|| ( c/d e/f )"),
            DepSpec("a/b"),
        ]
        assert list(reversed(self.cls("|| ( u? ( a/b ) )"))) == [DepSpec("|| ( u? ( a/b ) )")]

    def test_iter_conditionals(self):
        assert list(self.cls("a/b").iter_conditionals()) == []
        assert list(self.cls("( a/b )").iter_conditionals()) == []
        assert list(self.cls("u? ( a/b )").iter_conditionals()) == ["u"]
        assert list(self.cls("!u? ( a/b )").iter_conditionals()) == ["u"]
        assert list(self.cls("|| ( u1? ( a/b !u2? ( c/d ) ) )").iter_conditionals()) == ["u1", "u2"]

    def test_iter_flatten(self):
        assert list(self.cls("a/b").iter_flatten()) == [Dep("a/b")]
        assert list(self.cls("!a/b").iter_flatten()) == [Dep("!a/b")]
        assert list(self.cls("( a/b )").iter_flatten()) == [Dep("a/b")]
        assert list(self.cls("|| ( a/b c/d )").iter_flatten()) == [Dep("a/b"), Dep("c/d")]
        assert list(self.cls("|| ( u? ( a/b ) )").iter_flatten()) == [Dep("a/b")]

    def test_iter_recursive(self):
        assert list(self.cls("a/b").iter_recursive()) == [DepSpec("a/b")]
        assert list(self.cls("!a/b").iter_recursive()) == [DepSpec("!a/b")]
        assert list(self.cls("( a/b )").iter_recursive()) == [DepSpec("( a/b )"), DepSpec("a/b")]
        assert list(self.cls("|| ( a/b c/d )").iter_recursive()) == [
            DepSpec("|| ( a/b c/d )"),
            DepSpec("a/b"),
            DepSpec("c/d"),
        ]
        assert list(self.cls("|| ( u? ( a/b ) )").iter_recursive()) == [
            DepSpec("|| ( u? ( a/b ) )"),
            DepSpec("u? ( a/b )"),
            DepSpec("a/b"),
        ]

    def test_evaluate(self):
        # no conditionals
        d = self.cls("a/b")
        assert d.evaluate() == d
        assert d.evaluate(["u"]) == d
        assert d.evaluate(True) == d
        assert d.evaluate(False) == d

        # conditionally enabled
        d1 = self.cls("u? ( a/b )")
        assert not d1.evaluate()
        assert d1.evaluate(["u"]) == d
        assert d1.evaluate(True) == d
        assert not d1.evaluate(False)

        # conditionally disabled
        d1 = self.cls("!u? ( a/b )")
        assert d1.evaluate() == d
        assert not d1.evaluate(["u"])
        assert d1.evaluate(True) == d
        assert not d1.evaluate(False)

        # empty DepSpecs are discarded
        d1 = self.cls("|| ( u1? ( a/b !u2? ( c/d ) ) )")
        assert not d1.evaluate()
        assert d1.evaluate(["u1"]) == self.cls("|| ( a/b c/d )")
        assert d1.evaluate(["u1", "u2"]) == self.cls("|| ( a/b )")
        assert not d1.evaluate(["u2"])
        assert d1.evaluate(True) == self.cls("|| ( a/b c/d )")
        assert not d1.evaluate(False)

    def test_contains(self):
        # only top-level DepSpec objects have membership
        assert DepSpec("a/b") in self.cls("a/b")
        assert DepSpec("a/b") not in self.cls("u? ( a/b )")

        # valid DepSpec strings work
        assert "a/b" in self.cls("a/b")
        assert "u? ( c/d )" in self.cls("a/b u? ( c/d )")

        # all other object types return False
        assert None not in self.cls("a/b")

    def test_eq_and_hash(self):
        # ordering that doesn't matter for equivalence and hashing
        for s1, s2 in (
            # same
            ("a/dep", "a/dep"),
            ("u? ( a/dep )", "u? ( a/dep )"),
            ("u? ( a/dep || ( a/b c/d ) )", "u? ( a/dep || ( a/b c/d ) )"),
            # different order, but equivalent
            ("a/b c/d", "c/d a/b"),
            ("u? ( a/b c/d )", "u? ( c/d a/b )"),
            ("|| ( a/b u? ( c/d b/d ) )", "|| ( a/b u? ( b/d c/d ) )"),
        ):
            dep1 = self.cls(s1)
            dep2 = self.cls(s2)
            assert dep1 == dep2, f"{dep1} != {dep2}"
            if self.cls == DepSet:
                assert len({dep1, dep2}) == 1

        # ordering that matters for equivalence and hashing
        for s1, s2 in (
            ("|| ( a/b c/d )", "|| ( c/d a/b )"),
            ("u? ( a/b || ( c/d b/d ) )", "u? ( a/b || ( b/d c/d ) )"),
        ):
            dep1 = self.cls(s1)
            dep2 = self.cls(s2)
            assert dep1 != dep2, f"{dep1} != {dep2}"
            if self.cls == DepSet:
                assert len({dep1, dep2}) == 2

        # verify incompatible type comparisons
        dep = self.cls("a/b")
        assert not dep == None
        assert dep != None

    def test_isdisjoint(self):
        d1 = self.cls()
        d2 = self.cls("a/b")
        d3 = self.cls("u? ( c/d ) a/b")
        assert d1.isdisjoint(d1)
        assert d1.isdisjoint(d2)
        assert d1.isdisjoint("")
        assert d2.isdisjoint("u? ( a/b )")
        assert not d2.isdisjoint(d2)
        assert not d2.isdisjoint(list(d2))
        assert not d2.isdisjoint(d3)

    def test_subset(self):
        d1 = self.cls()
        d2 = self.cls("a/b")
        d3 = self.cls("u? ( c/d ) a/b")
        assert d1 <= d1
        assert d1.issubset(d1)
        assert not d1 < d1
        assert d1 <= d2
        assert d1.issubset(d2)
        assert d1 < d2
        assert d1.issubset(list(d2))
        assert d1.issubset(str(d3))
        # operators don't convert strings or iterables to DepSet
        with pytest.raises(TypeError):
            d1 <= list(d2)
        with pytest.raises(TypeError):
            d1 < "a/b"

    def test_superset(self):
        d1 = self.cls()
        d2 = self.cls("a/b")
        d3 = self.cls("u? ( c/d ) a/b")
        assert d1 >= d1
        assert d1.issuperset(d1)
        assert not d1 > d1
        assert d2 >= d1
        assert d2.issuperset(d1)
        assert d2 > d1
        assert d2.issuperset(list(d1))
        assert d3.issuperset(str(d1))
        # operators don't convert strings or iterables to DepSet
        with pytest.raises(TypeError):
            d2 >= list(d1)
        with pytest.raises(TypeError):
            d2 > ""

    def test_union(self):
        d = self.cls("a/a b/b")

        # new depset matches the instance class
        assert d.union().__class__ == self.cls

        # no args
        assert d == d.union() and d is not d.union()

        # empty iterable
        assert d == d.union([])

        # DepSet args
        assert d == d.union(self.cls())
        assert d.union(self.cls("a/a"), self.cls("b/b c/c")) == self.cls("a/a b/b c/c")

        # DepSet string args
        assert d == d.union("")
        assert d.union("a/a", "b/b c/c") == self.cls("a/a b/b c/c")

        # DepSpec args
        assert d.union(DepSpec("c/c")) == self.cls("a/a b/b c/c")
        assert d.union(DepSpec("a/a"), DepSpec("c/c")) == self.cls("a/a b/b c/c")

    def test_intersection(self):
        d = self.cls("a/a b/b")

        # new depset matches the instance class
        assert d.intersection().__class__ == self.cls

        # no args
        assert d == d.intersection() and d is not d.intersection()

        # empty iterable
        assert not d.intersection([])

        # DepSet args
        assert not d.intersection(self.cls())
        assert d == d.intersection(d)
        assert d.intersection(self.cls("a/a b/b"), self.cls("b/b")) == self.cls("b/b")

        # DepSet string args
        assert not d.intersection("")
        assert d.intersection("a/a b/b", "b/b") == self.cls("b/b")

        # DepSpec args
        assert d.intersection(DepSpec("a/a")) == self.cls("a/a")
        assert d.intersection(DepSpec("a/a"), DepSpec("c/c")) == self.cls()

    def test_difference(self):
        d = self.cls("a/a b/b")

        # new depset matches the instance class
        assert d.difference().__class__ == self.cls

        # no args
        assert d == d.difference() and d is not d.difference()

        # empty iterable
        assert d == d.difference([])

        # DepSet args
        assert d == d.difference(self.cls())
        assert d.difference(self.cls("a/a"), self.cls("b/b c/c")) == self.cls()

        # DepSet string args
        assert d == d.difference("")
        assert d.difference("a/a", "b/b c/c") == self.cls()

        # DepSpec args
        assert d.difference(DepSpec("b/b")) == self.cls("a/a")
        assert d.difference(DepSpec("a/a"), DepSpec("c/c")) == self.cls("b/b")

    def test_symmetric_difference(self):
        d = self.cls("a/a b/b")

        # new depset matches the instance class
        assert d.symmetric_difference().__class__ == self.cls

        # no args
        assert d == d.symmetric_difference() and d is not d.symmetric_difference()

        # empty iterable
        assert d == d.symmetric_difference([])

        # DepSet args
        assert d == d.symmetric_difference(self.cls())
        assert d.symmetric_difference(self.cls("a/a"), self.cls("b/b c/c")) == self.cls("c/c")

        # DepSet string args
        assert d == d.symmetric_difference("")
        assert d.symmetric_difference("a/a", "b/b c/c") == self.cls("c/c")

        # DepSpec args
        assert d.symmetric_difference(DepSpec("b/b")) == self.cls("a/a")
        assert d.symmetric_difference(DepSpec("a/a"), DepSpec("c/c")) == self.cls("b/b c/c")

    def test_getitem(self):
        d = self.cls("a/b || ( c/d e/f )")

        # slices
        assert d[:] == d and d[:] is not d
        assert d[:1] == self.cls("a/b")

        # integers
        assert d[0] == DepSpec("a/b")
        assert d[-1] == DepSpec("|| ( c/d e/f )")

        # nonexistent indices
        for idx in [5, -5]:
            with pytest.raises(IndexError):
                d[idx]

        # invalid arg types
        for obj in [None, "a/b", object()]:
            with pytest.raises(TypeError):
                d[obj]

    def test_iand(self):
        d = self.cls("a/a b/b c/c")
        d &= self.cls("a/a b/b")
        assert d == self.cls("a/a b/b")
        d &= self.cls("a/a")
        assert d == self.cls("a/a")
        d &= self.cls()
        assert d == self.cls()
        # invalid
        for obj in [None, "s", self.req_use()]:
            with pytest.raises(TypeError):
                d &= obj

    def test_ior(self):
        d = self.cls()
        d |= self.cls("a/a b/b")
        assert d == self.cls("a/a b/b")
        d |= self.cls("c/c")
        assert d == self.cls("a/a b/b c/c")
        # all-of group doesn't combine with regular deps
        d = self.cls("a/a")
        d |= self.cls("( a/a )")
        assert d == self.cls("a/a ( a/a )")
        # invalid
        for obj in [None, "s", self.req_use()]:
            with pytest.raises(TypeError):
                d |= obj

    def test_ixor(self):
        d = self.cls("a/a b/b c/c")
        d ^= self.cls("a/a b/b")
        assert d == self.cls("c/c")
        d ^= self.cls("c/c d/d")
        assert d == self.cls("d/d")
        d ^= self.cls("d/d")
        assert d == self.cls()
        # invalid
        for obj in [None, "s", self.req_use()]:
            with pytest.raises(TypeError):
                d ^= obj

    def test_isub(self):
        d = self.cls("a/a b/b c/c")
        d -= self.cls("a/a b/b")
        assert d == self.cls("c/c")
        d -= self.cls("d/d")
        assert d == self.cls("c/c")
        d -= self.cls("c/c")
        assert d == self.cls()
        # invalid
        for obj in [None, "s", self.req_use()]:
            with pytest.raises(TypeError):
                d -= obj

    def test_and(self):
        d = self.cls("a/a b/b c/c")
        assert (d & self.cls("a/a b/b")) == self.cls("a/a b/b")
        assert (d & self.cls("c/c")) == self.cls("c/c")
        assert (d & self.cls("d/d")) == self.cls()
        assert (d & self.cls()) == self.cls()
        # invalid
        for obj in [None, "s", self.req_use()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x & y

    def test_or(self):
        d = self.cls("a/a")
        assert (d | self.cls("a/a b/b")) == self.cls("a/a b/b")
        assert (d | self.cls("c/c")) == self.cls("a/a c/c")
        assert (d | self.cls()) == self.cls("a/a")
        # invalid
        for obj in [None, "s", self.req_use()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x | y

    def test_xor(self):
        d = self.cls("a/a b/b c/c")
        assert (d ^ self.cls("b/b c/c")) == self.cls("a/a")
        assert (d ^ self.cls("c/c")) == self.cls("a/a b/b")
        assert (d ^ self.cls("d/d")) == self.cls("a/a b/b c/c d/d")
        assert (d ^ self.cls()) == self.cls("a/a b/b c/c")
        # invalid
        for obj in [None, "s", self.req_use()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x ^ y

    def test_sub(self):
        # - operator
        d = self.cls("a/a b/b c/c")
        assert (d - self.cls("b/b c/c")) == self.cls("a/a")
        assert (d - self.cls("c/c")) == self.cls("a/a b/b")
        assert (d - self.cls("d/d")) == self.cls("a/a b/b c/c")
        assert (d - self.cls()) == self.cls("a/a b/b c/c")
        # invalid
        for obj in [None, "s", self.req_use()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x - y


class TestDepSet(DepSetBase):
    cls = DepSet
    req_use = partial(DepSet, set=DepSetKind.RequiredUse)


class TestMutableDepSet(DepSetBase):
    cls = MutableDepSet
    req_use = partial(MutableDepSet, set=DepSetKind.RequiredUse)

    def test_freeze(self):
        d1 = MutableDepSet("a/a")

        # freeze the mutable depset to an immutable clone
        d2 = DepSet(d1)
        assert d1 == d2 and d1 is not d2
        assert d2.__class__ == DepSet

        # unfreeze the depset to a mutable clone
        d3 = MutableDepSet(d2)
        assert d1 == d3 and d1 is not d3
        assert d3.__class__ == MutableDepSet

        # mutable re-creation creates a clone
        assert MutableDepSet(d3) is not d3

    def test_add(self):
        d = MutableDepSet("a/a")
        d.add("a/a")
        assert d == MutableDepSet("a/a")
        d.add(DepSpec("b/b"))
        assert d == MutableDepSet("a/a b/b")

        # arguments must be DepSpec objects or strings
        for obj in [None, DepSet("c/c")]:
            with pytest.raises(TypeError):
                d.add(obj)

    def test_remove(self):
        d = MutableDepSet("a/a b/b")
        d.remove("a/a")
        d.remove(DepSpec("b/b"))
        for obj in ["a/a", DepSpec("c/c")]:
            with pytest.raises(KeyError):
                d.remove(obj)
        assert d == MutableDepSet()

        # arguments must be DepSpec objects or strings
        for obj in [None, DepSet("c/c")]:
            with pytest.raises(TypeError):
                d.remove(obj)

    def test_discard(self):
        d = MutableDepSet("a/a b/b")
        for obj in [None, "a/a", DepSpec("b/b"), MutableDepSet("c/c")]:
            d.discard(obj)
        assert d == MutableDepSet()

    def test_pop(self):
        d = MutableDepSet("a/a")
        assert d.pop() == DepSpec("a/a")
        with pytest.raises(KeyError):
            d.pop()
        assert d == MutableDepSet()

    def test_clear(self):
        d = MutableDepSet("a/a")
        d.clear()
        assert d == MutableDepSet()
        d.clear()

    def test_setitem(self):
        # slices
        d = MutableDepSet("a/b || ( c/d e/f )")
        d[:] = [DepSpec("a/b")]
        assert d == MutableDepSet("a/b")
        d[10:] = ["c/d", "a/b"]
        assert d == MutableDepSet("a/b c/d")

        # integers
        d = MutableDepSet("a/b || ( c/d e/f )")
        d[0] = DepSpec("cat/pkg")
        assert d == MutableDepSet("cat/pkg || ( c/d e/f )")
        d[-1] = DepSpec("u? ( a/b )")
        assert d == MutableDepSet("cat/pkg u? ( a/b )")
        d[-1] = "cat/pkg[u1,u2]"
        assert d == MutableDepSet("cat/pkg cat/pkg[u1,u2]")

        # DepSpec and valid DepSpec strings
        d = MutableDepSet("a/b || ( c/d e/f )")
        d["a/b"] = "c/d"
        assert d == MutableDepSet("c/d || ( c/d e/f )")
        d["c/d"] = DepSpec("e/f")
        assert d == MutableDepSet("e/f || ( c/d e/f )")
        d[DepSpec("|| ( c/d e/f )")] = "a/b"
        assert d == MutableDepSet("e/f a/b")
        d[DepSpec("e/f")] = DepSpec("c/d")
        assert d == MutableDepSet("c/d a/b")

        # inserting an existing value removes the value at the specified index
        d = MutableDepSet("a/b c/d e/f")
        d[-1] = DepSpec("a/b")
        assert d == MutableDepSet("a/b c/d")
        d["a/b"] = "c/d"
        assert d == MutableDepSet("c/d")

        # nonexistent indices
        for idx in [5, -5]:
            with pytest.raises(IndexError):
                d[idx] = DepSpec("cat/pkg")

        # invalid arg types
        d = MutableDepSet("a/b")
        for obj in [None, object(), "a/b"]:
            with pytest.raises(TypeError):
                d[:] = obj
        for obj in [None, object()]:
            with pytest.raises(TypeError):
                d[obj] = DepSpec("a/b")
            for key in [0, "a/b", DepSpec("a/b")]:
                with pytest.raises(TypeError):
                    d[key] = obj

    def test_update(self):
        d = MutableDepSet("a/a b/b")

        # no args
        d1 = d[:]
        assert d1 == d1.update() and d1 is d1.update()

        # empty iterable
        assert d == MutableDepSet(d).update([])

        # DepSet args
        assert d == MutableDepSet(d).update(MutableDepSet())
        assert MutableDepSet(d).update(
            MutableDepSet("a/a"), MutableDepSet("b/b c/c")
        ) == MutableDepSet("a/a b/b c/c")

        # DepSet string args
        assert d == MutableDepSet(d).update("")
        assert MutableDepSet(d).update("a/a", "b/b c/c") == MutableDepSet("a/a b/b c/c")

        # DepSpec args
        assert MutableDepSet(d).update(DepSpec("c/c")) == MutableDepSet("a/a b/b c/c")
        assert MutableDepSet(d).update(DepSpec("a/a"), DepSpec("c/c")) == MutableDepSet(
            "a/a b/b c/c"
        )

    def test_intersection_update(self):
        d = MutableDepSet("a/a b/b")

        # no args
        d1 = d[:]
        assert d1 == d1.intersection_update() and d1 is d1.intersection_update()

        # empty iterable
        assert not MutableDepSet(d).intersection_update([])

        # DepSet args
        assert not MutableDepSet(d).intersection_update(MutableDepSet())
        assert d == MutableDepSet(d).intersection_update(d)
        assert MutableDepSet(d).intersection_update(
            MutableDepSet("a/a b/b"), MutableDepSet("b/b")
        ) == MutableDepSet("b/b")

        # DepSet string args
        assert not MutableDepSet(d).intersection_update("")
        assert MutableDepSet(d).intersection_update("a/a b/b", "b/b") == MutableDepSet("b/b")

        # DepSpec args
        assert MutableDepSet(d).intersection_update(DepSpec("a/a")) == MutableDepSet("a/a")
        assert (
            MutableDepSet(d).intersection_update(DepSpec("a/a"), DepSpec("c/c")) == MutableDepSet()
        )

    def test_difference_update(self):
        d = MutableDepSet("a/a b/b")

        # no args
        d1 = d[:]
        assert d1 == d1.difference_update() and d1 is d1.difference_update()

        # empty iterable
        assert d == MutableDepSet(d).difference_update([])

        # DepSet args
        assert d == MutableDepSet(d).difference_update(MutableDepSet())
        assert (
            MutableDepSet(d).difference_update(MutableDepSet("a/a"), MutableDepSet("b/b c/c"))
            == MutableDepSet()
        )

        # DepSet string args
        assert d == MutableDepSet(d).difference_update("")
        assert MutableDepSet(d).difference_update("a/a", "b/b c/c") == MutableDepSet()

        # DepSpec args
        assert MutableDepSet(d).difference_update(DepSpec("b/b")) == MutableDepSet("a/a")
        assert MutableDepSet(d).difference_update(DepSpec("a/a"), DepSpec("c/c")) == MutableDepSet(
            "b/b"
        )

    def test_symmetric_difference_update(self):
        d = MutableDepSet("a/a b/b")

        # no args
        d1 = d[:]
        assert d1 == d1.symmetric_difference_update() and d1 is d1.symmetric_difference_update()

        # empty iterable
        assert d == MutableDepSet(d).symmetric_difference_update([])

        # DepSet args
        assert d == MutableDepSet(d).symmetric_difference_update(MutableDepSet())
        assert MutableDepSet(d).symmetric_difference_update(
            MutableDepSet("a/a"), MutableDepSet("b/b c/c")
        ) == MutableDepSet("c/c")

        # DepSet string args
        assert d == MutableDepSet(d).symmetric_difference_update("")
        assert MutableDepSet(d).symmetric_difference_update("a/a", "b/b c/c") == MutableDepSet(
            "c/c"
        )

        # DepSpec args
        assert MutableDepSet(d).symmetric_difference_update(DepSpec("b/b")) == MutableDepSet("a/a")
        assert MutableDepSet(d).symmetric_difference_update(
            DepSpec("a/a"), DepSpec("c/c")
        ) == MutableDepSet("b/b c/c")

    def test_hash(self):
        with pytest.raises(TypeError):
            hash(MutableDepSet())
