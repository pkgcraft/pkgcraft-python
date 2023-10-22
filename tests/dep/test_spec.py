import pytest

from pkgcraft.dep import *
from pkgcraft.eapi import EAPI8
from pkgcraft.error import InvalidDep


class TestDepSpec:
    def test_parse(self):
        # only works with subclasses
        with pytest.raises(TypeError):
            DepSet.dep_spec("a/b")

        # empty strings fail
        with pytest.raises(TypeError):
            Dependencies.dep_spec("")

        # multiple DepSpecs fail
        with pytest.raises(TypeError):
            Dependencies.dep_spec("a/b c/d")

        # variants
        d = RequiredUse.dep_spec("a")
        assert isinstance(d, Enabled)
        d = RequiredUse.dep_spec("!a")
        assert isinstance(d, Disabled)
        d = RequiredUse.dep_spec("( a b )")
        assert isinstance(d, AllOf)
        d = RequiredUse.dep_spec("|| ( a b )")
        assert isinstance(d, AnyOf)
        d = RequiredUse.dep_spec("^^ ( a b )")
        assert isinstance(d, ExactlyOneOf)
        d = RequiredUse.dep_spec("?? ( a b )")
        assert isinstance(d, AtMostOneOf)
        d = RequiredUse.dep_spec("use? ( a )")
        assert isinstance(d, UseEnabled)
        d = RequiredUse.dep_spec("!use? ( a )")
        assert isinstance(d, UseDisabled)

    def test_evaluate(self):
        # no conditionals
        d = Dependencies.dep_spec("a/b")
        assert d.evaluate() == [d]
        assert d.evaluate(["use"]) == [d]
        assert d.evaluate(True) == [d]
        assert d.evaluate(False) == [d]

        # conditionally enabled
        d1 = Dependencies.dep_spec("use? ( a/b )")
        assert not d1.evaluate()
        assert d1.evaluate(["use"]) == [d]
        assert d1.evaluate(True) == [d]
        assert not d1.evaluate(False)

        # conditionally disabled
        d1 = Dependencies.dep_spec("!use? ( a/b )")
        assert d1.evaluate() == [d]
        assert not d1.evaluate(["use"])
        assert d1.evaluate(True) == [d]
        assert not d1.evaluate(False)
