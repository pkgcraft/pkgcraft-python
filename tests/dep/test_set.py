import pytest

from pkgcraft.dep import *
from pkgcraft.eapi import EAPI8
from pkgcraft.error import PkgcraftError


class TestDependencies:
    def test_parse(self):
        # empty
        d1 = Dependencies()
        assert not d1
        assert len(d1) == 0
        assert str(d1) == ""
        assert repr(d1).startswith("<Dependencies '' at 0x")

        # single
        d1 = Dependencies("a/b")
        assert d1
        assert len(d1) == 1
        assert str(d1) == "a/b"
        assert repr(d1).startswith("<Dependencies 'a/b' at 0x")
        assert d1 == Dependencies("a/b", EAPI8)

        # multiple
        d1 = Dependencies("a/b || ( c/d e/f )")
        assert d1
        assert len(d1) == 2
        assert str(d1) == "a/b || ( c/d e/f )"
        assert repr(d1).startswith("<Dependencies 'a/b || ( c/d e/f )' at 0x")

        # invalid
        with pytest.raises(PkgcraftError):
            Dependencies("a/b::repo", EAPI8)

        # invalid type
        with pytest.raises(TypeError):
            Dependencies(None)

    def test_from_iterable(self):
        # create from iterating over DepSet
        d = Dependencies()
        assert d == Dependencies(d)
        d = Dependencies("a/b || ( c/d e/f )")
        assert d == Dependencies(d)

        # create from DepSpec iterable
        d1 = Dependencies.dep_spec("a/b")
        d2 = Dependencies.dep_spec("c/d")
        assert str(Dependencies([d1, d2])) == "a/b c/d"

        # invalid types
        d = RequiredUse("a")
        with pytest.raises(PkgcraftError):
            Dependencies(d)

    def test_evaluate(self):
        # no conditionals
        d = Dependencies("a/b")
        assert d.evaluate() == d
        assert d.evaluate(["u"]) == d
        assert d.evaluate(True) == d
        assert d.evaluate(False) == d

        # conditionally enabled
        d1 = Dependencies("u? ( a/b )")
        assert not d1.evaluate()
        assert d1.evaluate(["u"]) == d
        assert d1.evaluate(True) == d
        assert not d1.evaluate(False)

        # conditionally disabled
        d1 = Dependencies("!u? ( a/b )")
        assert d1.evaluate() == d
        assert not d1.evaluate(["u"])
        assert d1.evaluate(True) == d
        assert not d1.evaluate(False)

        # empty DepSpecs are discarded
        d1 = Dependencies("|| ( u1? ( a/b !u2? ( c/d ) ) )")
        assert not d1.evaluate()
        assert d1.evaluate(["u1"]) == Dependencies("|| ( a/b c/d )")
        assert d1.evaluate(["u1", "u2"]) == Dependencies("|| ( a/b )")
        assert not d1.evaluate(["u2"])
        assert d1.evaluate(True) == Dependencies("|| ( a/b c/d )")
        assert not d1.evaluate(False)

    def test_contains(self):
        # only top-level DepSpec objects have membership
        assert Dependencies.dep_spec("a/b") in Dependencies("a/b")
        assert Dependencies.dep_spec("a/b") not in Dependencies("u? ( a/b )")

        # non-DepSpec objects return False
        assert None not in Dependencies("a/b")

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
            dep1 = Dependencies(s1)
            dep2 = Dependencies(s2)
            assert dep1 == dep2, f"{dep1} != {dep2}"
            assert len({dep1, dep2}) == 1

        # ordering that matters for equivalence and hashing
        for s1, s2 in (("|| ( a/b c/d )", "|| ( c/d a/b )"),):
            dep1 = Dependencies(s1)
            dep2 = Dependencies(s2)
            assert dep1 != dep2, f"{dep1} != {dep2}"
            assert len({dep1, dep2}) == 2

        # verify incompatible type comparisons
        dep = Dependencies("a/b")
        assert not dep == None
        assert dep != None

    def test_set_ops(self):
        # &= operator
        d = Dependencies("a/a b/b c/c")
        d &= Dependencies("a/a b/b")
        assert d == Dependencies("a/a b/b")
        d &= Dependencies("a/a")
        assert d == Dependencies("a/a")
        d &= Dependencies()
        assert d == Dependencies()
        # invalid
        for obj in [None, "s", License()]:
            with pytest.raises(TypeError):
                d &= obj

        # |= operator
        d = Dependencies()
        d |= Dependencies("a/a b/b")
        assert d == Dependencies("a/a b/b")
        d |= Dependencies("c/c")
        assert d == Dependencies("a/a b/b c/c")
        # all-of group doesn't combine with regular deps
        d = Dependencies("a/a")
        d |= Dependencies("( a/a )")
        assert d == Dependencies("a/a ( a/a )")
        # invalid
        for obj in [None, "s", License()]:
            with pytest.raises(TypeError):
                d |= obj

        # ^= operator
        d = Dependencies("a/a b/b c/c")
        d ^= Dependencies("a/a b/b")
        assert d == Dependencies("c/c")
        d ^= Dependencies("c/c d/d")
        assert d == Dependencies("d/d")
        d ^= Dependencies("d/d")
        assert d == Dependencies()
        # invalid
        for obj in [None, "s", License()]:
            with pytest.raises(TypeError):
                d ^= obj

        # -= operator
        d = Dependencies("a/a b/b c/c")
        d -= Dependencies("a/a b/b")
        assert d == Dependencies("c/c")
        d -= Dependencies("d/d")
        assert d == Dependencies("c/c")
        d -= Dependencies("c/c")
        assert d == Dependencies()
        # invalid
        for obj in [None, "s", License()]:
            with pytest.raises(TypeError):
                d -= obj

        # & operator
        d = Dependencies("a/a b/b c/c")
        assert (d & Dependencies("a/a b/b")) == Dependencies("a/a b/b")
        assert (d & Dependencies("c/c")) == Dependencies("c/c")
        assert (d & Dependencies("d/d")) == Dependencies()
        assert (d & Dependencies()) == Dependencies()
        # invalid
        for obj in [None, "s", License()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x & y

        # | operator
        d = Dependencies("a/a")
        assert (d | Dependencies("a/a b/b")) == Dependencies("a/a b/b")
        assert (d | Dependencies("c/c")) == Dependencies("a/a c/c")
        assert (d | Dependencies()) == Dependencies("a/a")
        # invalid
        for obj in [None, "s", License()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x | y

        # ^ operator
        d = Dependencies("a/a b/b c/c")
        assert (d ^ Dependencies("b/b c/c")) == Dependencies("a/a")
        assert (d ^ Dependencies("c/c")) == Dependencies("a/a b/b")
        assert (d ^ Dependencies("d/d")) == Dependencies("a/a b/b c/c d/d")
        assert (d ^ Dependencies()) == Dependencies("a/a b/b c/c")
        # invalid
        for obj in [None, "s", License()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x ^ y

        # - operator
        d = Dependencies("a/a b/b c/c")
        assert (d - Dependencies("b/b c/c")) == Dependencies("a/a")
        assert (d - Dependencies("c/c")) == Dependencies("a/a b/b")
        assert (d - Dependencies("d/d")) == Dependencies("a/a b/b c/c")
        assert (d - Dependencies()) == Dependencies("a/a b/b c/c")
        # invalid
        for obj in [None, "s", License()]:
            for x, y in [(d, obj), (obj, d)]:
                with pytest.raises(TypeError):
                    x - y


class TestLicense:
    def test_parse(self):
        d1 = License("a")
        assert str(d1) == "a"
        assert repr(d1).startswith("<License 'a' at 0x")

        with pytest.raises(PkgcraftError):
            License("!a")


class TestProperties:
    def test_parse(self):
        d1 = Properties("a")
        assert str(d1) == "a"
        assert repr(d1).startswith("<Properties 'a' at 0x")

        with pytest.raises(PkgcraftError):
            Properties("!a")


class TestRequiredUse:
    def test_parse(self):
        d1 = RequiredUse("use")
        assert str(d1) == "use"
        assert repr(d1).startswith("<RequiredUse 'use' at 0x")
        d2 = RequiredUse("use", EAPI8)
        assert d1 == d2

        with pytest.raises(PkgcraftError):
            RequiredUse("use!")


class TestRestrict:
    def test_parse(self):
        d1 = Restrict("a")
        assert str(d1) == "a"
        assert repr(d1).startswith("<Restrict 'a' at 0x")

        with pytest.raises(PkgcraftError):
            Restrict("!a")


class TestSrcUri:
    def test_parse(self):
        d1 = SrcUri("a")
        assert str(d1) == "a"
        assert repr(d1).startswith("<SrcUri 'a' at 0x")
        d2 = SrcUri("a", EAPI8)
        assert d1 == d2

        with pytest.raises(PkgcraftError):
            SrcUri("http://a/")
