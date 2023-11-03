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
        assert repr(d).startswith("<DepSpec Enabled 'a' at 0x")
        # EAPI specific
        assert d == self.req_use("a", eapi=str(EAPI_LATEST_OFFICIAL))
        assert d == self.req_use("a", eapi=EAPI_LATEST_OFFICIAL)

        d = self.req_use("!a")
        assert len(d) == 1
        assert str(d) == "!a"
        assert repr(d).startswith("<DepSpec Disabled '!a' at 0x")

        d = self.req_use("( a b )")
        assert len(d) == 2
        assert str(d) == "( a b )"
        assert repr(d).startswith("<DepSpec AllOf '( a b )' at 0x")

        d = self.req_use("|| ( a b )")
        assert len(d) == 2
        assert str(d) == "|| ( a b )"
        assert repr(d).startswith("<DepSpec AnyOf '|| ( a b )' at 0x")

        d = self.req_use("^^ ( a b )")
        assert len(d) == 2
        assert str(d) == "^^ ( a b )"
        assert repr(d).startswith("<DepSpec ExactlyOneOf '^^ ( a b )' at 0x")

        d = self.req_use("?? ( a b )")
        assert len(d) == 2
        assert str(d) == "?? ( a b )"
        assert repr(d).startswith("<DepSpec AtMostOneOf '?? ( a b )' at 0x")

        d = self.req_use("u? ( a )")
        assert len(d) == 1
        assert str(d) == "u? ( a )"
        assert repr(d).startswith("<DepSpec UseEnabled 'u? ( a )' at 0x")

        d = self.req_use("!u1? ( a u2? ( b ) )")
        assert len(d) == 2
        assert str(d) == "!u1? ( a u2? ( b ) )"
        assert repr(d).startswith("<DepSpec UseDisabled '!u1? ( a u2? ( b ) )' at 0x")

    def test_cmp(self):
        for (set1, set2) in (
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
        assert list(map(str, self.req_use("|| ( a b )").iter_recursive())) == ["|| ( a b )", "a", "b"]
        assert list(map(str, self.req_use("|| ( u? ( a ) )").iter_recursive())) == ["|| ( u? ( a ) )", "u? ( a )", "a"]

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


class TestDepSet:

    req_use = partial(DepSet, set=DepSetKind.RequiredUse)

    def test_creation(self):
        # empty DepSets
        d = DepSet()
        assert d == DepSet("")
        assert not d
        assert len(d) == 0
        assert str(d) == ""
        assert repr(d).startswith("<DepSet Dependencies '' at 0x")

        dep1 = DepSpec("a/b")
        dep2 = DepSpec("u? ( c/d )")

        # DepSpec arg
        d = DepSet(dep1)
        assert d == DepSet("a/b")
        assert d
        assert len(d) == 1
        assert str(d) == "a/b"
        assert repr(d).startswith("<DepSet Dependencies 'a/b' at 0x")

        # iterable of DepSpecs
        d = DepSet([dep1, dep2])
        assert d == DepSet("a/b u? ( c/d )")
        assert d
        assert len(d) == 2
        assert str(d) == "a/b u? ( c/d )"
        assert repr(d).startswith("<DepSet Dependencies 'a/b u? ( c/d )' at 0x")

        # iterable of DepSpec strings
        d = DepSet(["a/b", "|| ( c/d e/f )"])
        assert d == DepSet("a/b || ( c/d e/f )")
        assert d
        assert len(d) == 2
        assert str(d) == "a/b || ( c/d e/f )"
        assert repr(d).startswith("<DepSet Dependencies 'a/b || ( c/d e/f )' at 0x")

        # empty iterables
        assert DepSet([]) == DepSet(DepSet())

        # DepSet iterables
        d1 = DepSet("a/b c/d")
        d2 = DepSet(d1)
        assert d2 == d1
        assert d2 == DepSet(list(d2))
        # incompatible DepSets
        d1 = DepSet("a", set=DepSetKind.RequiredUse)
        with pytest.raises(PkgcraftError):
            d2 = DepSet(d1)

        # EAPI kwargs
        d1 = DepSet("a/b", eapi=EAPI_LATEST_OFFICIAL)
        d2 = DepSet("a/b", eapi=str(EAPI_LATEST_OFFICIAL))
        assert d1 == d2
        d3 = DepSet("a/b::repo", eapi=EAPI_LATEST)
        assert d1 != d3

        # DepSet set kwargs
        for (s, kind) in [
                ("a/b", DepSetKind.Dependencies),
                ("a", DepSetKind.License),
                ("a", DepSetKind.Properties),
                ("a", DepSetKind.RequiredUse),
                ("a", DepSetKind.Restrict),
                ("a", DepSetKind.SrcUri),
            ]:
            d = DepSet(s, set=kind)
            assert len(d) == 1

        # invalid DepSets
        with pytest.raises(PkgcraftError):
            DepSet("a")
        with pytest.raises(PkgcraftError):
            DepSet("a/b::repo", EAPI_LATEST_OFFICIAL)

        # invalid args
        for obj in [None, object()]:
            with pytest.raises(TypeError):
                DepSet(obj)

    def test_iter(self):
        assert list(DepSet()) == []
        assert list(iter(DepSet("a/b"))) == [DepSpec("a/b")]
        assert list(DepSet("( a/b )")) == [DepSpec("( a/b )")]
        assert list(DepSet("a/b || ( c/d e/f )")) == [DepSpec("a/b"), DepSpec("|| ( c/d e/f )")]
        assert list(DepSet("|| ( u? ( a/b ) )")) == [DepSpec("|| ( u? ( a/b ) )")]

    def test_iter_conditionals(self):
        assert list(DepSet("a/b").iter_conditionals()) == []
        assert list(DepSet("( a/b )").iter_conditionals()) == []
        assert list(DepSet("u? ( a/b )").iter_conditionals()) == ["u"]
        assert list(DepSet("!u? ( a/b )").iter_conditionals()) == ["u"]
        assert list(DepSet("|| ( u1? ( a/b !u2? ( c/d ) ) )").iter_conditionals()) == ["u1", "u2"]

    def test_iter_flatten(self):
        assert list(DepSet("a/b").iter_flatten()) == [Dep("a/b")]
        assert list(DepSet("!a/b").iter_flatten()) == [Dep("!a/b")]
        assert list(DepSet("( a/b )").iter_flatten()) == [Dep("a/b")]
        assert list(DepSet("|| ( a/b c/d )").iter_flatten()) == [Dep("a/b"), Dep("c/d")]
        assert list(DepSet("|| ( u? ( a/b ) )").iter_flatten()) == [Dep("a/b")]

    def test_iter_recursive(self):
        assert list(DepSet("a/b").iter_recursive()) == [DepSpec("a/b")]
        assert list(DepSet("!a/b").iter_recursive()) == [DepSpec("!a/b")]
        assert list(DepSet("( a/b )").iter_recursive()) == [DepSpec("( a/b )"), DepSpec("a/b")]
        assert list(DepSet("|| ( a/b c/d )").iter_recursive()) == [DepSpec("|| ( a/b c/d )"), DepSpec("a/b"), DepSpec("c/d")]
        assert list(DepSet("|| ( u? ( a/b ) )").iter_recursive()) == [DepSpec("|| ( u? ( a/b ) )"), DepSpec("u? ( a/b )"), DepSpec("a/b")]

    def test_evaluate(self):
        # no conditionals
        d = DepSet("a/b")
        assert d.evaluate() == d
        assert d.evaluate(["u"]) == d
        assert d.evaluate(True) == d
        assert d.evaluate(False) == d

        # conditionally enabled
        d1 = DepSet("u? ( a/b )")
        assert not d1.evaluate()
        assert d1.evaluate(["u"]) == d
        assert d1.evaluate(True) == d
        assert not d1.evaluate(False)

        # conditionally disabled
        d1 = DepSet("!u? ( a/b )")
        assert d1.evaluate() == d
        assert not d1.evaluate(["u"])
        assert d1.evaluate(True) == d
        assert not d1.evaluate(False)

        # empty DepSpecs are discarded
        d1 = DepSet("|| ( u1? ( a/b !u2? ( c/d ) ) )")
        assert not d1.evaluate()
        assert d1.evaluate(["u1"]) == DepSet("|| ( a/b c/d )")
        assert d1.evaluate(["u1", "u2"]) == DepSet("|| ( a/b )")
        assert not d1.evaluate(["u2"])
        assert d1.evaluate(True) == DepSet("|| ( a/b c/d )")
        assert not d1.evaluate(False)

    def test_contains(self):
        # only top-level DepSpec objects have membership
        assert DepSpec("a/b") in DepSet("a/b")
        assert DepSpec("a/b") not in DepSet("u? ( a/b )")

        # valid DepSpec strings work
        assert "a/b" in DepSet("a/b")
        assert "u? ( c/d )" in DepSet("a/b u? ( c/d )")

        # all other object types return False
        assert None not in DepSet("a/b")

    def test_eq_and_hash(self):
        # ordering that doesn't matter for equivalence and hashing
        for s1, s2 in (
            # same deps
            ("a/dep", "a/dep"),
            ("u? ( a/dep )", "u? ( a/dep )"),
            ("u? ( a/dep || ( a/b c/d ) )", "u? ( a/dep || ( a/b c/d ) )"),
            # different order, but equivalent
            ("a/b c/d", "c/d a/b"),
            ("u? ( a/b c/d )", "u? ( c/d a/b )"),
        ):
            dep1 = DepSet(s1)
            dep2 = DepSet(s2)
            assert dep1 == dep2, f"{dep1} != {dep2}"
            assert len({dep1, dep2}) == 1

        # ordering that matters for equivalence and hashing
        for s1, s2 in (("|| ( a/b c/d )", "|| ( c/d a/b )"),):
            dep1 = DepSet(s1)
            dep2 = DepSet(s2)
            assert dep1 != dep2, f"{dep1} != {dep2}"
            assert len({dep1, dep2}) == 2

        # verify incompatible type comparisons
        dep = DepSet("a/b")
        assert not dep == None
        assert dep != None

    def test_isdisjoint(self):
        d1 = DepSet()
        d2 = DepSet("a/b")
        d3 = DepSet("u? ( c/d ) a/b")
        assert d1.isdisjoint(d1)
        assert d1.isdisjoint(d2)
        assert d1.isdisjoint("")
        assert d2.isdisjoint("u? ( a/b )")
        assert not d2.isdisjoint(d2)
        assert not d2.isdisjoint(list(d2))
        assert not d2.isdisjoint(d3)

    def test_subset(self):
        d1 = DepSet()
        d2 = DepSet("a/b")
        d3 = DepSet("u? ( c/d ) a/b")
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
        d1 = DepSet()
        d2 = DepSet("a/b")
        d3 = DepSet("u? ( c/d ) a/b")
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
        d = DepSet("a/a b/b")

        # no args
        assert d == d.union() and d is not d.union()

        # empty iterable
        assert d == d.union([])

        # DepSet args
        assert d == d.union(DepSet())
        assert d.union(DepSet("a/a"), DepSet("b/b c/c")) == DepSet("a/a b/b c/c")

        # DepSet string args
        assert d == d.union("")
        assert d.union("a/a", "b/b c/c") == DepSet("a/a b/b c/c")

        # DepSpec args
        assert d.union(DepSpec("c/c")) == DepSet("a/a b/b c/c")
        assert d.union(DepSpec("a/a"), DepSpec("c/c")) == DepSet("a/a b/b c/c")

    def test_intersection(self):
        d = DepSet("a/a b/b")

        # no args
        assert d == d.intersection() and d is not d.intersection()

        # empty iterable
        assert not d.intersection([])

        # DepSet args
        assert not d.intersection(DepSet())
        assert d == d.intersection(d)
        assert d.intersection(DepSet("a/a b/b"), DepSet("b/b")) == DepSet("b/b")

        # DepSet string args
        assert not d.intersection("")
        assert d.intersection("a/a b/b", "b/b") == DepSet("b/b")

        # DepSpec args
        assert d.intersection(DepSpec("a/a")) == DepSet("a/a")
        assert d.intersection(DepSpec("a/a"), DepSpec("c/c")) == DepSet()

    def test_difference(self):
        d = DepSet("a/a b/b")

        # no args
        assert d == d.difference() and d is not d.difference()

        # empty iterable
        assert d == d.difference([])

        # DepSet args
        assert d == d.difference(DepSet())
        assert d.difference(DepSet("a/a"), DepSet("b/b c/c")) == DepSet()

        # DepSet string args
        assert d == d.difference("")
        assert d.difference("a/a", "b/b c/c") == DepSet()

        # DepSpec args
        assert d.difference(DepSpec("b/b")) == DepSet("a/a")
        assert d.difference(DepSpec("a/a"), DepSpec("c/c")) == DepSet("b/b")

    def test_symmetric_difference(self):
        d = DepSet("a/a b/b")

        # no args
        assert d == d.symmetric_difference() and d is not d.symmetric_difference()

        # empty iterable
        assert d == d.symmetric_difference([])

        # DepSet args
        assert d == d.symmetric_difference(DepSet())
        assert d.symmetric_difference(DepSet("a/a"), DepSet("b/b c/c")) == DepSet("c/c")

        # DepSet string args
        assert d == d.symmetric_difference("")
        assert d.symmetric_difference("a/a", "b/b c/c") == DepSet("c/c")

        # DepSpec args
        assert d.symmetric_difference(DepSpec("b/b")) == DepSet("a/a")
        assert d.symmetric_difference(DepSpec("a/a"), DepSpec("c/c")) == DepSet("b/b c/c")

    def test_update(self):
        d = DepSet("a/a b/b")

        # no args
        d1 = d[:]
        assert d1 == d1.update() and d1 is d1.update()

        # empty iterable
        assert d == DepSet(d).update([])

        # DepSet args
        assert d == DepSet(d).update(DepSet())
        assert DepSet(d).update(DepSet("a/a"), DepSet("b/b c/c")) == DepSet("a/a b/b c/c")

        # DepSet string args
        assert d == DepSet(d).update("")
        assert DepSet(d).update("a/a", "b/b c/c") == DepSet("a/a b/b c/c")

        # DepSpec args
        assert DepSet(d).update(DepSpec("c/c")) == DepSet("a/a b/b c/c")
        assert DepSet(d).update(DepSpec("a/a"), DepSpec("c/c")) == DepSet("a/a b/b c/c")

    def test_intersection_update(self):
        d = DepSet("a/a b/b")

        # no args
        d1 = d[:]
        assert d1 == d1.intersection_update() and d1 is d1.intersection_update()

        # empty iterable
        assert not DepSet(d).intersection_update([])

        # DepSet args
        assert not DepSet(d).intersection_update(DepSet())
        assert d == DepSet(d).intersection_update(d)
        assert DepSet(d).intersection_update(DepSet("a/a b/b"), DepSet("b/b")) == DepSet("b/b")

        # DepSet string args
        assert not DepSet(d).intersection_update("")
        assert DepSet(d).intersection_update("a/a b/b", "b/b") == DepSet("b/b")

        # DepSpec args
        assert DepSet(d).intersection_update(DepSpec("a/a")) == DepSet("a/a")
        assert DepSet(d).intersection_update(DepSpec("a/a"), DepSpec("c/c")) == DepSet()

    def test_difference_update(self):
        d = DepSet("a/a b/b")

        # no args
        d1 = d[:]
        assert d1 == d1.difference_update() and d1 is d1.difference_update()

        # empty iterable
        assert d == DepSet(d).difference_update([])

        # DepSet args
        assert d == DepSet(d).difference_update(DepSet())
        assert DepSet(d).difference_update(DepSet("a/a"), DepSet("b/b c/c")) == DepSet()

        # DepSet string args
        assert d == DepSet(d).difference_update("")
        assert DepSet(d).difference_update("a/a", "b/b c/c") == DepSet()

        # DepSpec args
        assert DepSet(d).difference_update(DepSpec("b/b")) == DepSet("a/a")
        assert DepSet(d).difference_update(DepSpec("a/a"), DepSpec("c/c")) == DepSet("b/b")

    def test_symmetric_difference_update(self):
        d = DepSet("a/a b/b")

        # no args
        d1 = d[:]
        assert d1 == d1.symmetric_difference_update() and d1 is d1.symmetric_difference_update()

        # empty iterable
        assert d == DepSet(d).symmetric_difference_update([])

        # DepSet args
        assert d == DepSet(d).symmetric_difference_update(DepSet())
        assert DepSet(d).symmetric_difference_update(DepSet("a/a"), DepSet("b/b c/c")) == DepSet("c/c")

        # DepSet string args
        assert d == DepSet(d).symmetric_difference_update("")
        assert DepSet(d).symmetric_difference_update("a/a", "b/b c/c") == DepSet("c/c")

        # DepSpec args
        assert DepSet(d).symmetric_difference_update(DepSpec("b/b")) == DepSet("a/a")
        assert DepSet(d).symmetric_difference_update(DepSpec("a/a"), DepSpec("c/c")) == DepSet("b/b c/c")

    def test_add(self):
        d = DepSet("a/a")
        d.add("a/a")
        assert d == DepSet("a/a")
        d.add(DepSpec("b/b"))
        assert d == DepSet("a/a b/b")

        # arguments must be DepSpec objects or strings
        for obj in [None, DepSet("c/c")]:
            with pytest.raises(TypeError):
                d.add(obj)

    def test_remove(self):
        d = DepSet("a/a b/b")
        d.remove("a/a")
        d.remove(DepSpec("b/b"))
        for obj in ["a/a", DepSpec("c/c")]:
            with pytest.raises(KeyError):
                d.remove(obj)
        assert d == DepSet()

        # arguments must be DepSpec objects or strings
        for obj in [None, DepSet("c/c")]:
            with pytest.raises(TypeError):
                d.remove(obj)

    def test_discard(self):
        d = DepSet("a/a b/b")
        for obj in [None, "a/a", DepSpec("b/b"), DepSet("c/c")]:
            d.discard(obj)
        assert d == DepSet()

    def test_pop(self):
        d = DepSet("a/a")
        assert d.pop() == DepSpec("a/a")
        with pytest.raises(KeyError):
            d.pop()
        assert d == DepSet()

    def test_clear(self):
        d = DepSet("a/a")
        d.clear()
        assert d == DepSet()
        d.clear()

    def test_getitem(self):
        d = DepSet("a/b || ( c/d e/f )")

        # slices return new DepSets
        assert d[:] == d and d[:] is not d
        assert d[:1] == DepSet("a/b")

        # integer indexes return DepSpec objects if they exist
        assert d[0] == DepSpec("a/b")
        assert d[-1] == DepSpec("|| ( c/d e/f )")
        with pytest.raises(IndexError):
            d[2]

    def test_iand(self):
        d = DepSet("a/a b/b c/c")
        d &= DepSet("a/a b/b")
        assert d == DepSet("a/a b/b")
        d &= DepSet("a/a")
        assert d == DepSet("a/a")
        d &= DepSet()
        assert d == DepSet()
        # invalid
        for obj in [None, "s", self.req_use()]:
            with pytest.raises(TypeError):
                d &= obj

    def test_ior(self):
        d = DepSet()
        d |= DepSet("a/a b/b")
        assert d == DepSet("a/a b/b")
        d |= DepSet("c/c")
        assert d == DepSet("a/a b/b c/c")
        # all-of group doesn't combine with regular deps
        d = DepSet("a/a")
        d |= DepSet("( a/a )")
        assert d == DepSet("a/a ( a/a )")
        # invalid
        for obj in [None, "s", self.req_use()]:
            with pytest.raises(TypeError):
                d |= obj

    def test_ixor(self):
        d = DepSet("a/a b/b c/c")
        d ^= DepSet("a/a b/b")
        assert d == DepSet("c/c")
        d ^= DepSet("c/c d/d")
        assert d == DepSet("d/d")
        d ^= DepSet("d/d")
        assert d == DepSet()
        # invalid
        for obj in [None, "s", self.req_use()]:
            with pytest.raises(TypeError):
                d ^= obj

    def test_isub(self):
        d = DepSet("a/a b/b c/c")
        d -= DepSet("a/a b/b")
        assert d == DepSet("c/c")
        d -= DepSet("d/d")
        assert d == DepSet("c/c")
        d -= DepSet("c/c")
        assert d == DepSet()
        # invalid
        for obj in [None, "s", self.req_use()]:
            with pytest.raises(TypeError):
                d -= obj

    def test_and(self):
        d = DepSet("a/a b/b c/c")
        assert (d & DepSet("a/a b/b")) == DepSet("a/a b/b")
        assert (d & DepSet("c/c")) == DepSet("c/c")
        assert (d & DepSet("d/d")) == DepSet()
        assert (d & DepSet()) == DepSet()
        # invalid
        for obj in [None, "s", self.req_use()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x & y

    def test_or(self):
        d = DepSet("a/a")
        assert (d | DepSet("a/a b/b")) == DepSet("a/a b/b")
        assert (d | DepSet("c/c")) == DepSet("a/a c/c")
        assert (d | DepSet()) == DepSet("a/a")
        # invalid
        for obj in [None, "s", self.req_use()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x | y

    def test_xor(self):
        d = DepSet("a/a b/b c/c")
        assert (d ^ DepSet("b/b c/c")) == DepSet("a/a")
        assert (d ^ DepSet("c/c")) == DepSet("a/a b/b")
        assert (d ^ DepSet("d/d")) == DepSet("a/a b/b c/c d/d")
        assert (d ^ DepSet()) == DepSet("a/a b/b c/c")
        # invalid
        for obj in [None, "s", self.req_use()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x ^ y

    def test_sub(self):
        # - operator
        d = DepSet("a/a b/b c/c")
        assert (d - DepSet("b/b c/c")) == DepSet("a/a")
        assert (d - DepSet("c/c")) == DepSet("a/a b/b")
        assert (d - DepSet("d/d")) == DepSet("a/a b/b c/c")
        assert (d - DepSet()) == DepSet("a/a b/b c/c")
        # invalid
        for obj in [None, "s", self.req_use()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x - y
