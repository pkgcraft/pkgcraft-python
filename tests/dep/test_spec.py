import pytest

from pkgcraft.dep import *


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

        d = RequiredUse.dep_spec("!u? ( a u2? ( b ) )")
        assert isinstance(d, UseDisabled)
        assert len(d) == 2

    def test_evaluate(self):
        # no conditionals
        d = Dependencies.dep_spec("a/b")
        assert d.evaluate() == [d]
        assert d.evaluate(["use"]) == [d]
        assert d.evaluate(True) == [d]
        assert d.evaluate(False) == [d]

        # conditionally enabled
        d1 = Dependencies.dep_spec("use? ( a/b )")
        assert d1.evaluate() == []
        assert d1.evaluate(["use"]) == [d]
        assert d1.evaluate(True) == [d]
        assert d1.evaluate(False) == []

        # conditionally disabled
        d1 = Dependencies.dep_spec("!use? ( a/b )")
        assert d1.evaluate() == [d]
        assert d1.evaluate(["use"]) == []
        assert d1.evaluate(True) == [d]
        assert d1.evaluate(False) == []
