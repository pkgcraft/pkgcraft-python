import pytest

from pkgcraft.dep import *
from pkgcraft.eapi import EAPI8
from pkgcraft.error import InvalidDep


class TestDependencies:
    def test_parse(self):
        # empty
        d1 = Dependencies()
        assert not d1
        assert str(d1) == ""
        assert repr(d1).startswith("<Dependencies '' at 0x")

        # default latest and specified EAPI
        d1 = Dependencies("a/b")
        assert d1
        assert str(d1) == "a/b"
        assert repr(d1).startswith("<Dependencies 'a/b' at 0x")
        d2 = Dependencies("a/b", EAPI8)
        assert d1 == d2

        # invalid
        with pytest.raises(InvalidDep):
            Dependencies("a/b::repo", EAPI8)

    def test_dep_spec(self):
        d = Dependencies.dep_spec("a/b")
        assert isinstance(d, Enabled)
        d = Dependencies.dep_spec("|| ( a/b c/d )")
        assert isinstance(d, AnyOf)

        # invalid
        for s in ["", "a/b c/d"]:
            with pytest.raises(TypeError):
                Dependencies.dep_spec(s)

    def test_evaluate(self):
        # no conditionals
        cond_none = Dependencies("a/b")
        assert cond_none.evaluate() == cond_none
        assert cond_none.evaluate(["use"]) == cond_none
        assert cond_none.evaluate(True) == cond_none
        assert cond_none.evaluate(False) == cond_none

        # conditionally enabled
        cond_enabled = Dependencies("use? ( a/b )")
        assert not cond_enabled.evaluate()
        assert cond_enabled.evaluate(["use"]) == cond_none
        assert cond_enabled.evaluate(True) == cond_none
        assert not cond_enabled.evaluate(False)

        # conditionally disabled
        cond_disabled = Dependencies("!use? ( a/b )")
        assert cond_disabled.evaluate() == cond_none
        assert not cond_disabled.evaluate(["use"])
        assert cond_enabled.evaluate(True) == cond_none
        assert not cond_enabled.evaluate(False)

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

        with pytest.raises(InvalidDep):
            License("!a")


class TestProperties:
    def test_parse(self):
        d1 = Properties("a")
        assert str(d1) == "a"
        assert repr(d1).startswith("<Properties 'a' at 0x")

        with pytest.raises(InvalidDep):
            Properties("!a")


class TestRequiredUse:
    def test_parse(self):
        d1 = RequiredUse("use")
        assert str(d1) == "use"
        assert repr(d1).startswith("<RequiredUse 'use' at 0x")
        d2 = RequiredUse("use", EAPI8)
        assert d1 == d2

        with pytest.raises(InvalidDep):
            RequiredUse("use!")


class TestRestrict:
    def test_parse(self):
        d1 = Restrict("a")
        assert str(d1) == "a"
        assert repr(d1).startswith("<Restrict 'a' at 0x")

        with pytest.raises(InvalidDep):
            Restrict("!a")


class TestSrcUri:
    def test_parse(self):
        d1 = SrcUri("a")
        assert str(d1) == "a"
        assert repr(d1).startswith("<SrcUri 'a' at 0x")
        d2 = SrcUri("a", EAPI8)
        assert d1 == d2

        with pytest.raises(InvalidDep):
            SrcUri("http://a/")
