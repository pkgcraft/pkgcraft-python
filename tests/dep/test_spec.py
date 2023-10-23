import pytest

from pkgcraft.dep import *
from pkgcraft.error import PkgcraftError


class TestDepSpec:
    def test_parse(self):
        # only defined in subclasses
        with pytest.raises(AttributeError):
            DepSet.dep_spec("a/b")

        # empty strings fail
        with pytest.raises(PkgcraftError):
            Dependencies.dep_spec("")

        # multiple DepSpecs fail
        with pytest.raises(PkgcraftError):
            Dependencies.dep_spec("a/b c/d")

        # variants
        d = RequiredUse.dep_spec("a")
        assert isinstance(d, Enabled)
        assert len(d) == 1

        d = RequiredUse.dep_spec("!a")
        assert isinstance(d, Disabled)
        assert len(d) == 1

        d = RequiredUse.dep_spec("( a b )")
        assert isinstance(d, AllOf)
        assert len(d) == 2

        d = RequiredUse.dep_spec("|| ( a b )")
        assert isinstance(d, AnyOf)
        assert len(d) == 2

        d = RequiredUse.dep_spec("^^ ( a b )")
        assert isinstance(d, ExactlyOneOf)
        assert len(d) == 2

        d = RequiredUse.dep_spec("?? ( a b )")
        assert isinstance(d, AtMostOneOf)
        assert len(d) == 2

        d = RequiredUse.dep_spec("u? ( a )")
        assert isinstance(d, UseEnabled)
        assert len(d) == 1

        d = RequiredUse.dep_spec("!u1? ( a u2? ( b ) )")
        assert isinstance(d, UseDisabled)
        assert len(d) == 2

    def test_contains(self):
        # simple DepSpecs don't contain themselves
        assert RequiredUse.dep_spec("a") not in RequiredUse.dep_spec("a")

        # only top-level DepSpec objects have membership
        d = RequiredUse.dep_spec("!u1? ( a u2? ( b ) )")
        assert RequiredUse.dep_spec("a") in d
        assert RequiredUse.dep_spec("u2? ( b )") in d
        assert RequiredUse.dep_spec("b") not in d

        # non-DepSpec objects return False
        assert None not in d

    def test_iter(self):
        assert list(RequiredUse.dep_spec("a")) == []
        assert list(iter(RequiredUse.dep_spec("!a"))) == []
        assert list(map(str, RequiredUse.dep_spec("( a )"))) == ["a"]
        assert list(map(str, RequiredUse.dep_spec("|| ( a b )"))) == ["a", "b"]
        assert list(map(str, RequiredUse.dep_spec("|| ( a? ( b ) )"))) == ["a? ( b )"]

    def test_iter_flatten(self):
        assert list(RequiredUse.dep_spec("a").iter_flatten()) == ["a"]
        assert list(RequiredUse.dep_spec("!a").iter_flatten()) == ["a"]
        assert list(RequiredUse.dep_spec("( a )").iter_flatten()) == ["a"]
        assert list(RequiredUse.dep_spec("|| ( a b )").iter_flatten()) == ["a", "b"]
        assert list(RequiredUse.dep_spec("|| ( a? ( b ) )").iter_flatten()) == ["b"]

    def test_iter_recursive(self):
        assert list(map(str, RequiredUse.dep_spec("a").iter_recursive())) == ["a"]
        assert list(map(str, RequiredUse.dep_spec("!a").iter_recursive())) == ["!a"]
        assert list(map(str, RequiredUse.dep_spec("( a )").iter_recursive())) == ["( a )", "a"]
        assert list(map(str, RequiredUse.dep_spec("|| ( a b )").iter_recursive())) == ["|| ( a b )", "a", "b"]
        assert list(map(str, RequiredUse.dep_spec("|| ( a? ( b ) )").iter_recursive())) == ["|| ( a? ( b ) )", "a? ( b )", "b"]

    def test_evaluate(self):
        req_use = RequiredUse.dep_spec
        d = req_use("a")

        # no conditionals
        assert d.evaluate() == [d]
        assert d.evaluate(["u"]) == [d]
        assert d.evaluate(True) == [d]
        assert d.evaluate(False) == [d]

        # conditionally enabled
        d1 = req_use("u? ( a )")
        assert d1.evaluate() == []
        assert d1.evaluate(["u"]) == [d]
        assert d1.evaluate(True) == [d]
        assert d1.evaluate(False) == []
        d1 = req_use("u? ( a b )")
        assert d1.evaluate(["u"]) == [req_use("a"), req_use("b")]

        # conditionally disabled
        d1 = req_use("!u? ( a )")
        assert d1.evaluate() == [d]
        assert d1.evaluate(["u"]) == []
        assert d1.evaluate(True) == [d]
        assert d1.evaluate(False) == []

        # empty DepSpecs are discarded
        d1 = req_use("|| ( u1? ( a !u2? ( b ) ) )")
        assert not d1.evaluate()
        assert d1.evaluate(["u1"]) == [req_use("|| ( a b )")]
        assert d1.evaluate(["u1", "u2"]) == [req_use("|| ( a )")]
        assert d1.evaluate(["u2"]) == []
        assert d1.evaluate(True) == [req_use("|| ( a b )")]
        assert not d1.evaluate(False)
