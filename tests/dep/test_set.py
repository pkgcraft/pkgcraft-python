from functools import partial

import pytest

from pkgcraft.dep import *
from pkgcraft.eapi import EAPI_LATEST_OFFICIAL
from pkgcraft.error import PkgcraftError


class TestDependencies:

    depset = partial(DepSet, set=DepSetKind.Dependencies)
    depspec = partial(DepSpec, set=DepSetKind.Dependencies)

    def test_parse(self):
        # empty
        d1 = self.depset()
        assert not d1
        assert len(d1) == 0
        assert str(d1) == ""
        assert repr(d1).startswith("<DepSet '' at 0x")

        # single
        d1 = self.depset("a/b")
        assert d1
        assert len(d1) == 1
        assert str(d1) == "a/b"
        assert repr(d1).startswith("<DepSet 'a/b' at 0x")
        assert d1 == self.depset("a/b", EAPI_LATEST_OFFICIAL)

        # multiple
        d1 = self.depset("a/b || ( c/d e/f )")
        assert d1
        assert len(d1) == 2
        assert str(d1) == "a/b || ( c/d e/f )"
        assert repr(d1).startswith("<DepSet 'a/b || ( c/d e/f )' at 0x")

        # invalid
        with pytest.raises(PkgcraftError):
            self.depset("a/b::repo", EAPI_LATEST_OFFICIAL)

        # invalid type
        with pytest.raises(TypeError):
            self.depset(None)

    def test_from_iterable(self):
        # create from iterating over DepSet
        d = self.depset()
        assert d == self.depset(d)
        d = self.depset("a/b || ( c/d e/f )")
        assert d == self.depset(d)
        assert d == self.depset(list(d))
        assert d == d[:]

        # create from parsing DepSpec strings
        assert d == self.depset(["a/b", "|| ( c/d e/f )"])

        # invalid types
        d = DepSet("a", set=DepSetKind.RequiredUse)
        with pytest.raises(PkgcraftError):
            self.depset(d)

    def test_evaluate(self):
        # no conditionals
        d = self.depset("a/b")
        assert d.evaluate() == d
        assert d.evaluate(["u"]) == d
        assert d.evaluate(True) == d
        assert d.evaluate(False) == d

        # conditionally enabled
        d1 = self.depset("u? ( a/b )")
        assert not d1.evaluate()
        assert d1.evaluate(["u"]) == d
        assert d1.evaluate(True) == d
        assert not d1.evaluate(False)

        # conditionally disabled
        d1 = self.depset("!u? ( a/b )")
        assert d1.evaluate() == d
        assert not d1.evaluate(["u"])
        assert d1.evaluate(True) == d
        assert not d1.evaluate(False)

        # empty DepSpecs are discarded
        d1 = self.depset("|| ( u1? ( a/b !u2? ( c/d ) ) )")
        assert not d1.evaluate()
        assert d1.evaluate(["u1"]) == self.depset("|| ( a/b c/d )")
        assert d1.evaluate(["u1", "u2"]) == self.depset("|| ( a/b )")
        assert not d1.evaluate(["u2"])
        assert d1.evaluate(True) == self.depset("|| ( a/b c/d )")
        assert not d1.evaluate(False)

    def test_contains(self):
        # only top-level DepSpec objects have membership
        assert self.depspec("a/b") in self.depset("a/b")
        assert self.depspec("a/b") not in self.depset("u? ( a/b )")

        # valid DepSpec strings work
        assert "a/b" in self.depset("a/b")
        assert "u? ( c/d )" in self.depset("a/b u? ( c/d )")

        # all other object types return False
        assert None not in self.depset("a/b")

    def test_eq_and_hash(self):
        # ordering that doesn't matter for equivalence and hashing
        for s1, s2 in (
            # same deps
            ("a/dep", "a/dep"),
            ("use? ( a/dep )", "use? ( a/dep )"),
            ("use? ( a/dep || ( a/b c/d ) )", "use? ( a/dep || ( a/b c/d ) )"),
            # different order, but equivalent
            ("a/b c/d", "c/d a/b"),
            ("use? ( a/b c/d )", "use? ( c/d a/b )"),
        ):
            dep1 = self.depset(s1)
            dep2 = self.depset(s2)
            assert dep1 == dep2, f"{dep1} != {dep2}"
            assert len({dep1, dep2}) == 1

        # ordering that matters for equivalence and hashing
        for s1, s2 in (("|| ( a/b c/d )", "|| ( c/d a/b )"),):
            dep1 = self.depset(s1)
            dep2 = self.depset(s2)
            assert dep1 != dep2, f"{dep1} != {dep2}"
            assert len({dep1, dep2}) == 2

        # verify incompatible type comparisons
        dep = self.depset("a/b")
        assert not dep == None
        assert dep != None

    def test_set_functionality(self):
        # disjoint
        d1 = self.depset()
        d2 = self.depset("a/b")
        d3 = self.depset("u? ( c/d ) a/b")
        assert d1.isdisjoint(d1)
        assert d1.isdisjoint(d2)
        assert d1.isdisjoint("")
        assert d2.isdisjoint("u? ( a/b )")
        assert not d2.isdisjoint(d2)
        assert not d2.isdisjoint(list(d2))
        assert not d2.isdisjoint(d3)

        # subset
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

        # superset
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

        req_use = partial(DepSet, set=DepSetKind.RequiredUse)

        # &= operator
        d = self.depset("a/a b/b c/c")
        d &= self.depset("a/a b/b")
        assert d == self.depset("a/a b/b")
        d &= self.depset("a/a")
        assert d == self.depset("a/a")
        d &= self.depset()
        assert d == self.depset()
        # invalid
        for obj in [None, "s", req_use()]:
            with pytest.raises(TypeError):
                d &= obj

        # |= operator
        d = self.depset()
        d |= self.depset("a/a b/b")
        assert d == self.depset("a/a b/b")
        d |= self.depset("c/c")
        assert d == self.depset("a/a b/b c/c")
        # all-of group doesn't combine with regular deps
        d = self.depset("a/a")
        d |= self.depset("( a/a )")
        assert d == self.depset("a/a ( a/a )")
        # invalid
        for obj in [None, "s", req_use()]:
            with pytest.raises(TypeError):
                d |= obj

        # ^= operator
        d = self.depset("a/a b/b c/c")
        d ^= self.depset("a/a b/b")
        assert d == self.depset("c/c")
        d ^= self.depset("c/c d/d")
        assert d == self.depset("d/d")
        d ^= self.depset("d/d")
        assert d == self.depset()
        # invalid
        for obj in [None, "s", req_use()]:
            with pytest.raises(TypeError):
                d ^= obj

        # -= operator
        d = self.depset("a/a b/b c/c")
        d -= self.depset("a/a b/b")
        assert d == self.depset("c/c")
        d -= self.depset("d/d")
        assert d == self.depset("c/c")
        d -= self.depset("c/c")
        assert d == self.depset()
        # invalid
        for obj in [None, "s", req_use()]:
            with pytest.raises(TypeError):
                d -= obj

        # & operator
        d = self.depset("a/a b/b c/c")
        assert (d & self.depset("a/a b/b")) == self.depset("a/a b/b")
        assert (d & self.depset("c/c")) == self.depset("c/c")
        assert (d & self.depset("d/d")) == self.depset()
        assert (d & self.depset()) == self.depset()
        # invalid
        for obj in [None, "s", req_use()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x & y

        # | operator
        d = self.depset("a/a")
        assert (d | self.depset("a/a b/b")) == self.depset("a/a b/b")
        assert (d | self.depset("c/c")) == self.depset("a/a c/c")
        assert (d | self.depset()) == self.depset("a/a")
        # invalid
        for obj in [None, "s", req_use()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x | y

        # ^ operator
        d = self.depset("a/a b/b c/c")
        assert (d ^ self.depset("b/b c/c")) == self.depset("a/a")
        assert (d ^ self.depset("c/c")) == self.depset("a/a b/b")
        assert (d ^ self.depset("d/d")) == self.depset("a/a b/b c/c d/d")
        assert (d ^ self.depset()) == self.depset("a/a b/b c/c")
        # invalid
        for obj in [None, "s", req_use()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x ^ y

        # - operator
        d = self.depset("a/a b/b c/c")
        assert (d - self.depset("b/b c/c")) == self.depset("a/a")
        assert (d - self.depset("c/c")) == self.depset("a/a b/b")
        assert (d - self.depset("d/d")) == self.depset("a/a b/b c/c")
        assert (d - self.depset()) == self.depset("a/a b/b c/c")
        # invalid
        for obj in [None, "s", req_use()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x - y


class TestLicense:

    depset = partial(DepSet, set=DepSetKind.License)
    depspec = partial(DepSpec, set=DepSetKind.License)

    def test_parse(self):
        d1 = self.depset("a")
        assert str(d1) == "a"
        assert repr(d1).startswith("<DepSet 'a' at 0x")

        with pytest.raises(PkgcraftError):
            self.depset("!a")

        # invalid type
        with pytest.raises(TypeError):
            self.depset(None)

    def test_from_iterable(self):
        # create from iterating over DepSet
        d = self.depset()
        assert d == self.depset(d)
        d = self.depset("a u? ( b c )")
        assert d == self.depset(d)
        assert d == self.depset(list(d))
        assert d == d[:]

        # create from parsing DepSpec strings
        assert d == self.depset(["a", "u? ( b c )"])

        # invalid types
        d = DepSet("a", set=DepSetKind.RequiredUse)
        with pytest.raises(PkgcraftError):
            self.depset(d)


class TestProperties:

    depset = partial(DepSet, set=DepSetKind.Properties)
    depspec = partial(DepSpec, set=DepSetKind.Properties)

    def test_parse(self):
        d1 = self.depset("a")
        assert str(d1) == "a"
        assert repr(d1).startswith("<DepSet 'a' at 0x")

        with pytest.raises(PkgcraftError):
            self.depset("!a")

        # invalid type
        with pytest.raises(TypeError):
            self.depset(None)

    def test_from_iterable(self):
        # create from iterating over DepSet
        d = self.depset()
        assert d == self.depset(d)
        d = self.depset("a u? ( b c )")
        assert d == self.depset(d)
        assert d == self.depset(list(d))
        assert d == d[:]

        # create from parsing DepSpec strings
        assert d == self.depset(["a", "u? ( b c )"])

        # invalid types
        d = DepSet("a", set=DepSetKind.RequiredUse)
        with pytest.raises(PkgcraftError):
            self.depset(d)


class TestRequiredUse:

    depset = partial(DepSet, set=DepSetKind.RequiredUse)
    depspec = partial(DepSpec, set=DepSetKind.RequiredUse)

    def test_parse(self):
        d1 = self.depset("use")
        assert str(d1) == "use"
        assert repr(d1).startswith("<DepSet 'use' at 0x")
        d2 = self.depset("use", EAPI_LATEST_OFFICIAL)
        assert d1 == d2

        with pytest.raises(PkgcraftError):
            self.depset("use!")

        # invalid type
        with pytest.raises(TypeError):
            self.depset(None)

    def test_from_iterable(self):
        # create from iterating over DepSet
        d = self.depset()
        assert d == self.depset(d)
        d = self.depset("a u? ( b c )")
        assert d == self.depset(d)
        assert d == self.depset(list(d))
        assert d == d[:]

        # create from parsing DepSpec strings
        assert d == self.depset(["a", "u? ( b c )"])

        # invalid types
        d = DepSet("a", set=DepSetKind.Properties)
        with pytest.raises(PkgcraftError):
            self.depset(d)


class TestRestrict:

    depset = partial(DepSet, set=DepSetKind.Restrict)
    depspec = partial(DepSpec, set=DepSetKind.Restrict)

    def test_parse(self):
        d1 = self.depset("a")
        assert str(d1) == "a"
        assert repr(d1).startswith("<DepSet 'a' at 0x")

        with pytest.raises(PkgcraftError):
            self.depset("!a")

        # invalid type
        with pytest.raises(TypeError):
            self.depset(None)

    def test_from_iterable(self):
        # create from iterating over DepSet
        d = self.depset()
        assert d == self.depset(d)
        d = self.depset("a u? ( b c )")
        assert d == self.depset(d)
        assert d == self.depset(list(d))
        assert d == d[:]

        # create from parsing DepSpec strings
        assert d == self.depset(["a", "u? ( b c )"])

        # invalid types
        d = DepSet("a", set=DepSetKind.Properties)
        with pytest.raises(PkgcraftError):
            self.depset(d)


class TestSrcUri:

    depset = partial(DepSet, set=DepSetKind.SrcUri)
    depspec = partial(DepSpec, set=DepSetKind.SrcUri)

    def test_parse(self):
        d1 = self.depset("a")
        assert str(d1) == "a"
        assert repr(d1).startswith("<DepSet 'a' at 0x")
        d2 = self.depset("a", EAPI_LATEST_OFFICIAL)
        assert d1 == d2

        with pytest.raises(PkgcraftError):
            self.depset("http://a/")

        # invalid type
        with pytest.raises(TypeError):
            self.depset(None)

    def test_from_iterable(self):
        # create from iterating over DepSet
        d = self.depset()
        assert d == self.depset(d)
        d = self.depset("a u? ( b c )")
        assert d == self.depset(d)
        assert d == self.depset(list(d))
        assert d == d[:]

        # create from parsing DepSpec strings
        assert d == self.depset(["a", "u? ( b c )"])

        # invalid types
        d = DepSet("a", set=DepSetKind.Properties)
        with pytest.raises(PkgcraftError):
            self.depset(d)
