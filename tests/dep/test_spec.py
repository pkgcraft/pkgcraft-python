import pytest

from pkgcraft.dep import *
from pkgcraft.error import PkgcraftError

from ..misc import OperatorMap


class TestDepSpec:
    def test_parse(self):
        # only valid in subclasses
        with pytest.raises(TypeError):
            DepSet.dep_spec("a/b")

        # empty strings fail
        with pytest.raises(PkgcraftError):
            Dependencies.dep_spec("")

        # multiple DepSpecs fail
        with pytest.raises(PkgcraftError):
            Dependencies.dep_spec("a/b c/d")

        # variants
        d = RequiredUse.dep_spec("a")
        assert d.kind == DepSpecKind.Enabled
        assert len(d) == 1
        assert str(d) == "a"
        assert repr(d).startswith("<DepSpec 'a' at 0x")

        d = RequiredUse.dep_spec("!a")
        assert d.kind == DepSpecKind.Disabled
        assert len(d) == 1
        assert str(d) == "!a"
        assert repr(d).startswith("<DepSpec '!a' at 0x")

        d = RequiredUse.dep_spec("( a b )")
        assert d.kind == DepSpecKind.AllOf
        assert len(d) == 2
        assert str(d) == "( a b )"

        d = RequiredUse.dep_spec("|| ( a b )")
        assert d.kind == DepSpecKind.AnyOf
        assert len(d) == 2
        assert str(d) == "|| ( a b )"

        d = RequiredUse.dep_spec("^^ ( a b )")
        assert d.kind == DepSpecKind.ExactlyOneOf
        assert len(d) == 2
        assert str(d) == "^^ ( a b )"

        d = RequiredUse.dep_spec("?? ( a b )")
        assert d.kind == DepSpecKind.AtMostOneOf
        assert len(d) == 2
        assert str(d) == "?? ( a b )"

        d = RequiredUse.dep_spec("u? ( a )")
        assert d.kind == DepSpecKind.UseEnabled
        assert len(d) == 1
        assert str(d) == "u? ( a )"

        d = RequiredUse.dep_spec("!u1? ( a u2? ( b ) )")
        assert d.kind == DepSpecKind.UseDisabled
        assert len(d) == 2
        assert str(d) == "!u1? ( a u2? ( b ) )"

    def test_cmp(self):
        for d1, op, d2 in (
            ("a/b", "<", "b/a"),
            ("a/b", "<=", "b/a"),
            ("b/a", "<=", "b/a"),
            ("b/a", "==", "b/a"),
            ("b/a", "!=", "a/b"),
            ("b/a", ">=", "a/b"),
            ("b/a", ">", "a/b"),
        ):
            op_func = OperatorMap[op]
            d1 = Dependencies.dep_spec(d1)
            d2 = Dependencies.dep_spec(d2)
            assert op_func(d1, d2), f"failed {d1} {op} {d2}"

        # verify incompatible type comparisons
        obj = RequiredUse.dep_spec("a")
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
        for d1, d2 in (
            # same
            ("a", "a"),
            ("u? ( a )", "u? ( a )"),
            ("u? ( a || ( a b ) )", "u? ( a || ( a b ) )"),
            # different order, but equivalent
            ("( a b )", "( b a )"),
            ("u? ( a b )", "u? ( b a )"),
            ("!u? ( a b )", "!u? ( b a )"),
        ):
            d1 = RequiredUse.dep_spec(d1)
            d2 = RequiredUse.dep_spec(d2)
            assert d1 == d2
            assert len({d1, d2}) == 1

        # ordering that matters for equivalence and hashing
        for d1, d2 in (
            ("|| ( a b )", "|| ( b a )"),
            ("?? ( a b )", "?? ( b a )"),
            ("^^ ( a b )", "^^ ( b a )"),
        ):
            d1 = RequiredUse.dep_spec(d1)
            d2 = RequiredUse.dep_spec(d2)
            assert d1 != d2
            assert len({d1, d2}) == 2

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

    def test_iter_conditionals(self):
        assert list(RequiredUse.dep_spec("a").iter_conditionals()) == []
        assert list(RequiredUse.dep_spec("( a )").iter_conditionals()) == []
        assert list(RequiredUse.dep_spec("u? ( a )").iter_conditionals()) == ["u"]
        assert list(RequiredUse.dep_spec("!u? ( a )").iter_conditionals()) == ["u"]
        assert list(RequiredUse.dep_spec("|| ( a? ( b !c? ( d ) ) )").iter_conditionals()) == ["a", "c"]

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
