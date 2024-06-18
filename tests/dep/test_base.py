import pytest

from pkgcraft.dep import *
from pkgcraft.eapi import EAPI_LATEST, EAPI_LATEST_OFFICIAL
from pkgcraft.error import PkgcraftError

from ..misc import OperatorMap


class TestDependency:
    def test_creation(self):
        # empty strings fail
        with pytest.raises(PkgcraftError):
            Dependency("")

        # multiple dependencies fail
        with pytest.raises(PkgcraftError):
            Dependency("a/b c/d")

        # variants
        d = Dependency.required_use("a")
        assert len(d) == 1
        assert str(d) == "a"
        assert d.kind == DependencyKind.Enabled
        assert d.set == DependencySetKind.RequiredUse
        assert d.conditional is None
        assert "Enabled 'a' at 0x" in repr(d)
        # EAPI specific
        assert d == Dependency.required_use("a")
        assert d == Dependency.required_use("a")

        d = Dependency.required_use("!a")
        assert len(d) == 1
        assert str(d) == "!a"
        assert d.kind == DependencyKind.Disabled
        assert d.conditional is None
        assert "Disabled '!a' at 0x" in repr(d)

        d = Dependency.required_use("( a b )")
        assert len(d) == 2
        assert str(d) == "( a b )"
        assert d.kind == DependencyKind.AllOf
        assert d.conditional is None
        assert "AllOf '( a b )' at 0x" in repr(d)

        d = Dependency.required_use("|| ( a b )")
        assert len(d) == 2
        assert str(d) == "|| ( a b )"
        assert d.kind == DependencyKind.AnyOf
        assert d.conditional is None
        assert "AnyOf '|| ( a b )' at 0x" in repr(d)

        d = Dependency.required_use("^^ ( a b )")
        assert len(d) == 2
        assert str(d) == "^^ ( a b )"
        assert d.kind == DependencyKind.ExactlyOneOf
        assert d.conditional is None
        assert "ExactlyOneOf '^^ ( a b )' at 0x" in repr(d)

        d = Dependency.required_use("?? ( a b )")
        assert len(d) == 2
        assert str(d) == "?? ( a b )"
        assert d.kind == DependencyKind.AtMostOneOf
        assert d.conditional is None
        assert "AtMostOneOf '?? ( a b )' at 0x" in repr(d)

        d = Dependency.required_use("u? ( a )")
        assert len(d) == 1
        assert str(d) == "u? ( a )"
        assert d.kind == DependencyKind.Conditional
        assert d.conditional == UseDep("u?")
        assert "Conditional 'u? ( a )' at 0x" in repr(d)

        d = Dependency.required_use("!u1? ( a u2? ( b ) )")
        assert len(d) == 2
        assert str(d) == "!u1? ( a u2? ( b ) )"
        assert d.kind == DependencyKind.Conditional
        assert d.conditional == UseDep("!u1?")
        assert "Conditional '!u1? ( a u2? ( b ) )' at 0x" in repr(d)

        # raw Deps
        d = Dependency(Dep("a/b"))
        assert len(d) == 1
        assert str(d) == "a/b"
        assert "Enabled 'a/b' at 0x" in repr(d)

        # invalid args
        for obj in [None, object()]:
            with pytest.raises(TypeError):
                Dependency(obj)

    def test_cmp(self):
        for set1, set2 in (
            (DependencySetKind.RequiredUse, DependencySetKind.RequiredUse),
            (DependencySetKind.RequiredUse, DependencySetKind.License),
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
                d1 = Dependency(s1, set=set1)
                d2 = Dependency(s2, set=set2)
                assert op_func(d1, d2), f"failed {d1} {op} {d2}"

        # verify incompatible type comparisons
        obj = Dependency.required_use("a")
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
            d1 = Dependency.required_use(s1)
            d2 = Dependency.required_use(s2)
            assert d1 == d2
            assert len({d1, d2}) == 1

        # ordering that matters for equivalence and hashing
        for s1, s2 in (
            ("|| ( a b )", "|| ( b a )"),
            ("?? ( a b )", "?? ( b a )"),
            ("^^ ( a b )", "^^ ( b a )"),
            ("u? ( a || ( c b ) )", "u? ( a || ( b c ) )"),
        ):
            d1 = Dependency.required_use(s1)
            d2 = Dependency.required_use(s2)
            assert d1 != d2
            assert len({d1, d2}) == 2

    def test_contains(self):
        d = Dependency.required_use("!u1? ( a u2? ( b ) )")

        # Dependency objects
        assert d in d
        assert Dependency.required_use("a") in d
        assert Dependency.required_use("u2? ( b )") in d
        assert Dependency.required_use("b") in d

        # UseDep objects
        assert UseDep("!u1?") in d
        assert UseDep("u2?") in d
        assert UseDep("u1") not in d
        assert UseDep("u") not in d

        # stringified, flattened values
        assert "a" in d
        assert "b" in d
        assert "( b )" not in d

        # all other object types return False
        for obj in (None, object()):
            assert obj not in d

    def test_iter(self):
        assert list(Dependency.required_use("a")) == []
        assert list(iter(Dependency.required_use("!a"))) == []
        assert list(map(str, Dependency.required_use("( a )"))) == ["a"]
        assert list(map(str, Dependency.required_use("|| ( a b )"))) == ["a", "b"]
        assert list(map(str, Dependency.required_use("|| ( u? ( a ) )"))) == ["u? ( a )"]

    def test_reversed(self):
        assert list(reversed(Dependency.required_use("a"))) == []
        assert list(reversed(Dependency.required_use("!a"))) == []
        assert list(map(str, reversed(Dependency.required_use("( a )")))) == ["a"]
        assert list(map(str, reversed(Dependency.required_use("|| ( a b )")))) == ["b", "a"]
        assert list(map(str, reversed(Dependency.required_use("|| ( u? ( a ) )")))) == ["u? ( a )"]

    def test_iter_conditionals(self):
        assert list(Dependency.required_use("a").iter_conditionals()) == []
        assert list(Dependency.required_use("( a )").iter_conditionals()) == []
        assert list(Dependency.required_use("u? ( a )").iter_conditionals()) == [UseDep("u?")]
        assert list(Dependency.required_use("!u? ( a )").iter_conditionals()) == [UseDep("!u?")]
        assert list(Dependency.required_use("|| ( u1? ( b !u2? ( d ) ) )").iter_conditionals()) == [
            UseDep("u1?"),
            UseDep("!u2?"),
        ]

    def test_iter_flatten(self):
        assert list(Dependency.required_use("a").iter_flatten()) == ["a"]
        assert list(Dependency.required_use("!a").iter_flatten()) == ["a"]
        assert list(Dependency.required_use("( a )").iter_flatten()) == ["a"]
        assert list(Dependency.required_use("|| ( a b )").iter_flatten()) == ["a", "b"]
        assert list(Dependency.required_use("|| ( u? ( a ) )").iter_flatten()) == ["a"]

    def test_iter_recursive(self):
        assert list(map(str, Dependency.required_use("a").iter_recursive())) == ["a"]
        assert list(map(str, Dependency.required_use("!a").iter_recursive())) == ["!a"]
        assert list(map(str, Dependency.required_use("( a )").iter_recursive())) == ["( a )", "a"]
        assert list(map(str, Dependency.required_use("|| ( a b )").iter_recursive())) == [
            "|| ( a b )",
            "a",
            "b",
        ]
        assert list(map(str, Dependency.required_use("|| ( u? ( a ) )").iter_recursive())) == [
            "|| ( u? ( a ) )",
            "u? ( a )",
            "a",
        ]

    def test_evaluate(self):
        d = Dependency.required_use("a")

        # no conditionals
        assert d.evaluate() == [d]
        assert d.evaluate(["u"]) == [d]
        assert d.evaluate(True) == [d]
        assert d.evaluate(False) == [d]

        # conditionally enabled
        d1 = Dependency.required_use("u? ( a )")
        assert d1.evaluate() == []
        assert d1.evaluate(["u"]) == [d]
        assert d1.evaluate(True) == [d]
        assert d1.evaluate(False) == []
        d1 = Dependency.required_use("u? ( a b )")
        assert d1.evaluate(["u"]) == [Dependency.required_use("a"), Dependency.required_use("b")]

        # conditionally disabled
        d1 = Dependency.required_use("!u? ( a )")
        assert d1.evaluate() == [d]
        assert d1.evaluate(["u"]) == []
        assert d1.evaluate(True) == [d]
        assert d1.evaluate(False) == []

        # empty dependencies are discarded
        d1 = Dependency.required_use("|| ( u1? ( a !u2? ( b ) ) )")
        assert not d1.evaluate()
        assert d1.evaluate(["u1"]) == [Dependency.required_use("|| ( a b )")]
        assert d1.evaluate(["u1", "u2"]) == [Dependency.required_use("|| ( a )")]
        assert d1.evaluate(["u2"]) == []
        assert d1.evaluate(True) == [Dependency.required_use("|| ( a b )")]
        assert not d1.evaluate(False)


class DependencySetBase:
    def test_creation(self):
        # empty DependencySets
        d = self.cls()
        assert d == self.cls("")
        assert not d
        assert len(d) == 0
        assert str(d) == ""
        assert "DependencySet Package '' at 0x" in repr(d)
        assert d.set == DependencySetKind.Package

        dep1 = Dependency("a/b")
        dep2 = Dependency("u? ( c/d )")

        # Dependency arg
        d = self.cls(dep1)
        assert d == self.cls("a/b")
        assert d
        assert len(d) == 1
        assert str(d) == "a/b"
        assert "DependencySet Package 'a/b' at 0x" in repr(d)

        # iterable of dependencies
        d = self.cls([dep1, dep2])
        assert d == self.cls("a/b u? ( c/d )")
        assert d
        assert len(d) == 2
        assert str(d) == "a/b u? ( c/d )"
        assert "DependencySet Package 'a/b u? ( c/d )' at 0x" in repr(d)

        # iterable of Dependency strings
        d = self.cls(["a/b", "|| ( c/d e/f )"])
        assert d == self.cls("a/b || ( c/d e/f )")
        assert d
        assert len(d) == 2
        assert str(d) == "a/b || ( c/d e/f )"
        assert "DependencySet Package 'a/b || ( c/d e/f )' at 0x" in repr(d)

        # empty iterables
        assert self.cls([]) == self.cls(self.cls())

        # DependencySet iterables
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
            ("a/b", DependencySetKind.Package),
            ("a", DependencySetKind.License),
            ("a", DependencySetKind.Properties),
            ("a", DependencySetKind.RequiredUse),
            ("a", DependencySetKind.Restrict),
            ("a", DependencySetKind.SrcUri),
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
        assert list(iter(self.cls("a/b"))) == [Dependency("a/b")]
        assert list(self.cls("( a/b )")) == [Dependency("( a/b )")]
        assert list(self.cls("a/b || ( c/d e/f )")) == [
            Dependency("a/b"),
            Dependency("|| ( c/d e/f )"),
        ]
        assert list(self.cls("|| ( u? ( a/b ) )")) == [Dependency("|| ( u? ( a/b ) )")]

    def test_reversed(self):
        assert list(reversed(self.cls())) == []
        assert list(reversed(self.cls("a/b"))) == [Dependency("a/b")]
        assert list(reversed(self.cls("( a/b )"))) == [Dependency("( a/b )")]
        assert list(reversed(self.cls("a/b || ( c/d e/f )"))) == [
            Dependency("|| ( c/d e/f )"),
            Dependency("a/b"),
        ]
        assert list(reversed(self.cls("|| ( u? ( a/b ) )"))) == [Dependency("|| ( u? ( a/b ) )")]

    def test_iter_conditionals(self):
        assert list(self.cls("a/b").iter_conditionals()) == []
        assert list(self.cls("( a/b )").iter_conditionals()) == []
        assert list(self.cls("u? ( a/b )").iter_conditionals()) == [UseDep("u?")]
        assert list(self.cls("!u? ( a/b )").iter_conditionals()) == [UseDep("!u?")]
        assert list(self.cls("|| ( u1? ( a/b !u2? ( c/d ) ) )").iter_conditionals()) == [
            UseDep("u1?"),
            UseDep("!u2?"),
        ]

    def test_iter_flatten(self):
        assert list(self.cls("a/b").iter_flatten()) == [Dep("a/b")]
        assert list(self.cls("!a/b").iter_flatten()) == [Dep("!a/b")]
        assert list(self.cls("( a/b )").iter_flatten()) == [Dep("a/b")]
        assert list(self.cls("|| ( a/b c/d )").iter_flatten()) == [Dep("a/b"), Dep("c/d")]
        assert list(self.cls("|| ( u? ( a/b ) )").iter_flatten()) == [Dep("a/b")]

    def test_iter_recursive(self):
        assert list(self.cls("a/b").iter_recursive()) == [Dependency("a/b")]
        assert list(self.cls("!a/b").iter_recursive()) == [Dependency("!a/b")]
        assert list(self.cls("( a/b )").iter_recursive()) == [
            Dependency("( a/b )"),
            Dependency("a/b"),
        ]
        assert list(self.cls("|| ( a/b c/d )").iter_recursive()) == [
            Dependency("|| ( a/b c/d )"),
            Dependency("a/b"),
            Dependency("c/d"),
        ]
        assert list(self.cls("|| ( u? ( a/b ) )").iter_recursive()) == [
            Dependency("|| ( u? ( a/b ) )"),
            Dependency("u? ( a/b )"),
            Dependency("a/b"),
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

        # empty dependencies are discarded
        d1 = self.cls("|| ( u1? ( a/b !u2? ( c/d ) ) )")
        assert not d1.evaluate()
        assert d1.evaluate(["u1"]) == self.cls("|| ( a/b c/d )")
        assert d1.evaluate(["u1", "u2"]) == self.cls("|| ( a/b )")
        assert not d1.evaluate(["u2"])
        assert d1.evaluate(True) == self.cls("|| ( a/b c/d )")
        assert not d1.evaluate(False)

    def test_contains(self):
        d = self.cls("!u1? ( a/b u2? ( b/c ) ) c/d")

        # Dependency objects
        assert Dependency("c/d") in d
        assert Dependency("u2? ( b/c )") in d

        # UseDep objects
        assert UseDep("!u1?") in d
        assert UseDep("u2?") in d
        assert UseDep("u1") not in d
        assert UseDep("u") not in d

        # stringified, flattened values
        assert "a/b" in d
        assert "c/d" in d
        assert "u2? ( b/c )" not in d
        assert "u2?" not in d

        # all other object types return False
        for obj in (None, object()):
            assert obj not in d

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
            if self.cls == DependencySet:
                assert len({dep1, dep2}) == 1

        # ordering that matters for equivalence and hashing
        for s1, s2 in (
            ("|| ( a/b c/d )", "|| ( c/d a/b )"),
            ("u? ( a/b || ( c/d b/d ) )", "u? ( a/b || ( b/d c/d ) )"),
        ):
            dep1 = self.cls(s1)
            dep2 = self.cls(s2)
            assert dep1 != dep2, f"{dep1} != {dep2}"
            if self.cls == DependencySet:
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
        # operators don't convert strings or iterables to DependencySet
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
        # operators don't convert strings or iterables to DependencySet
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

        # DependencySet args
        assert d == d.union(self.cls())
        assert d.union(self.cls("a/a"), self.cls("b/b c/c")) == self.cls("a/a b/b c/c")

        # DependencySet string args
        assert d == d.union("")
        assert d.union("a/a", "b/b c/c") == self.cls("a/a b/b c/c")

        # Dependency args
        assert d.union(Dependency("c/c")) == self.cls("a/a b/b c/c")
        assert d.union(Dependency("a/a"), Dependency("c/c")) == self.cls("a/a b/b c/c")

    def test_intersection(self):
        d = self.cls("a/a b/b")

        # new depset matches the instance class
        assert d.intersection().__class__ == self.cls

        # no args
        assert d == d.intersection() and d is not d.intersection()

        # empty iterable
        assert not d.intersection([])

        # DependencySet args
        assert not d.intersection(self.cls())
        assert d == d.intersection(d)
        assert d.intersection(self.cls("a/a b/b"), self.cls("b/b")) == self.cls("b/b")

        # DependencySet string args
        assert not d.intersection("")
        assert d.intersection("a/a b/b", "b/b") == self.cls("b/b")

        # Dependency args
        assert d.intersection(Dependency("a/a")) == self.cls("a/a")
        assert d.intersection(Dependency("a/a"), Dependency("c/c")) == self.cls()

    def test_difference(self):
        d = self.cls("a/a b/b")

        # new depset matches the instance class
        assert d.difference().__class__ == self.cls

        # no args
        assert d == d.difference() and d is not d.difference()

        # empty iterable
        assert d == d.difference([])

        # DependencySet args
        assert d == d.difference(self.cls())
        assert d.difference(self.cls("a/a"), self.cls("b/b c/c")) == self.cls()

        # DependencySet string args
        assert d == d.difference("")
        assert d.difference("a/a", "b/b c/c") == self.cls()

        # Dependency args
        assert d.difference(Dependency("b/b")) == self.cls("a/a")
        assert d.difference(Dependency("a/a"), Dependency("c/c")) == self.cls("b/b")

    def test_symmetric_difference(self):
        d = self.cls("a/a b/b")

        # new depset matches the instance class
        assert d.symmetric_difference().__class__ == self.cls

        # no args
        assert d == d.symmetric_difference() and d is not d.symmetric_difference()

        # empty iterable
        assert d == d.symmetric_difference([])

        # DependencySet args
        assert d == d.symmetric_difference(self.cls())
        assert d.symmetric_difference(self.cls("a/a"), self.cls("b/b c/c")) == self.cls("c/c")

        # DependencySet string args
        assert d == d.symmetric_difference("")
        assert d.symmetric_difference("a/a", "b/b c/c") == self.cls("c/c")

        # Dependency args
        assert d.symmetric_difference(Dependency("b/b")) == self.cls("a/a")
        assert d.symmetric_difference(Dependency("a/a"), Dependency("c/c")) == self.cls("b/b c/c")

    def test_getitem(self):
        d = self.cls("a/b || ( c/d e/f )")

        # slices
        assert d[:] == d and d[:] is not d
        assert d[:1] == self.cls("a/b")

        # integers
        assert d[0] == Dependency("a/b")
        assert d[-1] == Dependency("|| ( c/d e/f )")

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
        for obj in [None, "s", self.cls.required_use()]:
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
        for obj in [None, "s", self.cls.required_use()]:
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
        for obj in [None, "s", self.cls.required_use()]:
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
        for obj in [None, "s", self.cls.required_use()]:
            with pytest.raises(TypeError):
                d -= obj

    def test_and(self):
        d = self.cls("a/a b/b c/c")
        assert (d & self.cls("a/a b/b")) == self.cls("a/a b/b")
        assert (d & self.cls("c/c")) == self.cls("c/c")
        assert (d & self.cls("d/d")) == self.cls()
        assert (d & self.cls()) == self.cls()
        # invalid
        for obj in [None, "s", self.cls.required_use()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x & y

    def test_or(self):
        d = self.cls("a/a")
        assert (d | self.cls("a/a b/b")) == self.cls("a/a b/b")
        assert (d | self.cls("c/c")) == self.cls("a/a c/c")
        assert (d | self.cls()) == self.cls("a/a")
        # invalid
        for obj in [None, "s", self.cls.required_use()]:
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
        for obj in [None, "s", self.cls.required_use()]:
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
        for obj in [None, "s", self.cls.required_use()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x - y


class TestDependencySet(DependencySetBase):
    cls = DependencySet


class TestMutableDependencySet(DependencySetBase):
    cls = MutableDependencySet

    def test_freeze(self):
        d1 = MutableDependencySet("a/a")

        # freeze the mutable depset to an immutable clone
        d2 = DependencySet(d1)
        assert d1 == d2 and d1 is not d2
        assert d2.__class__ == DependencySet

        # unfreeze the depset to a mutable clone
        d3 = MutableDependencySet(d2)
        assert d1 == d3 and d1 is not d3
        assert d3.__class__ == MutableDependencySet

        # mutable re-creation creates a clone
        assert MutableDependencySet(d3) is not d3

    def test_add(self):
        d = MutableDependencySet("a/a")
        d.add("a/a")
        assert d == MutableDependencySet("a/a")
        d.add(Dependency("b/b"))
        assert d == MutableDependencySet("a/a b/b")

        # arguments must be Dependency objects or strings
        for obj in [None, DependencySet("c/c")]:
            with pytest.raises(TypeError):
                d.add(obj)

    def test_remove(self):
        d = MutableDependencySet("a/a b/b")
        d.remove("a/a")
        d.remove(Dependency("b/b"))
        for obj in ["a/a", Dependency("c/c")]:
            with pytest.raises(KeyError):
                d.remove(obj)
        assert d == MutableDependencySet()

        # arguments must be Dependency objects or strings
        for obj in [None, DependencySet("c/c")]:
            with pytest.raises(TypeError):
                d.remove(obj)

    def test_discard(self):
        d = MutableDependencySet("a/a b/b")
        for obj in [None, "a/a", Dependency("b/b"), MutableDependencySet("c/c")]:
            d.discard(obj)
        assert d == MutableDependencySet()

    def test_pop(self):
        d = MutableDependencySet("a/a")
        assert d.pop() == Dependency("a/a")
        with pytest.raises(KeyError):
            d.pop()
        assert d == MutableDependencySet()

    def test_clear(self):
        d = MutableDependencySet("a/a")
        d.clear()
        assert d == MutableDependencySet()
        d.clear()

    def test_setitem(self):
        # slices
        d = MutableDependencySet("a/b || ( c/d e/f )")
        d[:] = [Dependency("a/b")]
        assert d == MutableDependencySet("a/b")
        d[10:] = ["c/d", "a/b"]
        assert d == MutableDependencySet("a/b c/d")

        # integers
        d = MutableDependencySet("a/b || ( c/d e/f )")
        d[0] = Dependency("cat/pkg")
        assert d == MutableDependencySet("cat/pkg || ( c/d e/f )")
        d[-1] = Dependency("u? ( a/b )")
        assert d == MutableDependencySet("cat/pkg u? ( a/b )")
        d[-1] = "cat/pkg[u1,u2]"
        assert d == MutableDependencySet("cat/pkg cat/pkg[u1,u2]")

        # Dependency and valid Dependency strings
        d = MutableDependencySet("a/b || ( c/d e/f )")
        d["a/b"] = "c/d"
        assert d == MutableDependencySet("c/d || ( c/d e/f )")
        d["c/d"] = Dependency("e/f")
        assert d == MutableDependencySet("e/f || ( c/d e/f )")
        d[Dependency("|| ( c/d e/f )")] = "a/b"
        assert d == MutableDependencySet("e/f a/b")
        d[Dependency("e/f")] = Dependency("c/d")
        assert d == MutableDependencySet("c/d a/b")

        # inserting an existing value removes the value at the specified index
        d = MutableDependencySet("a/b c/d e/f")
        d[-1] = Dependency("a/b")
        assert d == MutableDependencySet("a/b c/d")
        d["a/b"] = "c/d"
        assert d == MutableDependencySet("c/d")

        # nonexistent indices
        for idx in [5, -5]:
            with pytest.raises(IndexError):
                d[idx] = Dependency("cat/pkg")

        # invalid arg types
        d = MutableDependencySet("a/b")
        for obj in [None, object(), "a/b"]:
            with pytest.raises(TypeError):
                d[:] = obj
        for obj in [None, object()]:
            with pytest.raises(TypeError):
                d[obj] = Dependency("a/b")
            for key in [0, "a/b", Dependency("a/b")]:
                with pytest.raises(TypeError):
                    d[key] = obj

    def test_update(self):
        d = MutableDependencySet("a/a b/b")

        # no args
        d1 = d[:]
        assert d1 == d1.update() and d1 is d1.update()

        # empty iterable
        assert d == MutableDependencySet(d).update([])

        # DependencySet args
        assert d == MutableDependencySet(d).update(MutableDependencySet())
        assert MutableDependencySet(d).update(
            MutableDependencySet("a/a"), MutableDependencySet("b/b c/c")
        ) == MutableDependencySet("a/a b/b c/c")

        # DependencySet string args
        assert d == MutableDependencySet(d).update("")
        assert MutableDependencySet(d).update("a/a", "b/b c/c") == MutableDependencySet(
            "a/a b/b c/c"
        )

        # Dependency args
        assert MutableDependencySet(d).update(Dependency("c/c")) == MutableDependencySet(
            "a/a b/b c/c"
        )
        assert MutableDependencySet(d).update(
            Dependency("a/a"), Dependency("c/c")
        ) == MutableDependencySet("a/a b/b c/c")

    def test_intersection_update(self):
        d = MutableDependencySet("a/a b/b")

        # no args
        d1 = d[:]
        assert d1 == d1.intersection_update() and d1 is d1.intersection_update()

        # empty iterable
        assert not MutableDependencySet(d).intersection_update([])

        # DependencySet args
        assert not MutableDependencySet(d).intersection_update(MutableDependencySet())
        assert d == MutableDependencySet(d).intersection_update(d)
        assert MutableDependencySet(d).intersection_update(
            MutableDependencySet("a/a b/b"), MutableDependencySet("b/b")
        ) == MutableDependencySet("b/b")

        # DependencySet string args
        assert not MutableDependencySet(d).intersection_update("")
        assert MutableDependencySet(d).intersection_update(
            "a/a b/b", "b/b"
        ) == MutableDependencySet("b/b")

        # Dependency args
        assert MutableDependencySet(d).intersection_update(
            Dependency("a/a")
        ) == MutableDependencySet("a/a")
        assert (
            MutableDependencySet(d).intersection_update(Dependency("a/a"), Dependency("c/c"))
            == MutableDependencySet()
        )

    def test_difference_update(self):
        d = MutableDependencySet("a/a b/b")

        # no args
        d1 = d[:]
        assert d1 == d1.difference_update() and d1 is d1.difference_update()

        # empty iterable
        assert d == MutableDependencySet(d).difference_update([])

        # DependencySet args
        assert d == MutableDependencySet(d).difference_update(MutableDependencySet())
        assert (
            MutableDependencySet(d).difference_update(
                MutableDependencySet("a/a"), MutableDependencySet("b/b c/c")
            )
            == MutableDependencySet()
        )

        # DependencySet string args
        assert d == MutableDependencySet(d).difference_update("")
        assert MutableDependencySet(d).difference_update("a/a", "b/b c/c") == MutableDependencySet()

        # Dependency args
        assert MutableDependencySet(d).difference_update(Dependency("b/b")) == MutableDependencySet(
            "a/a"
        )
        assert MutableDependencySet(d).difference_update(
            Dependency("a/a"), Dependency("c/c")
        ) == MutableDependencySet("b/b")

    def test_symmetric_difference_update(self):
        d = MutableDependencySet("a/a b/b")

        # no args
        d1 = d[:]
        assert d1 == d1.symmetric_difference_update() and d1 is d1.symmetric_difference_update()

        # empty iterable
        assert d == MutableDependencySet(d).symmetric_difference_update([])

        # DependencySet args
        assert d == MutableDependencySet(d).symmetric_difference_update(MutableDependencySet())
        assert MutableDependencySet(d).symmetric_difference_update(
            MutableDependencySet("a/a"), MutableDependencySet("b/b c/c")
        ) == MutableDependencySet("c/c")

        # DependencySet string args
        assert d == MutableDependencySet(d).symmetric_difference_update("")
        assert MutableDependencySet(d).symmetric_difference_update(
            "a/a", "b/b c/c"
        ) == MutableDependencySet("c/c")

        # Dependency args
        assert MutableDependencySet(d).symmetric_difference_update(
            Dependency("b/b")
        ) == MutableDependencySet("a/a")
        assert MutableDependencySet(d).symmetric_difference_update(
            Dependency("a/a"), Dependency("c/c")
        ) == MutableDependencySet("b/b c/c")

    def test_hash(self):
        with pytest.raises(TypeError):
            hash(MutableDependencySet())
