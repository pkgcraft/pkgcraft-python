from functools import partial

import pytest

from pkgcraft.dep import *
from pkgcraft.eapi import EAPI_LATEST_OFFICIAL
from pkgcraft.error import PkgcraftError

from ..misc import OperatorMap


class TestDepSpec:

    req_use = partial(DepSpec, set=DepSetKind.RequiredUse)

    def test_parse(self):
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
        assert list(map(str, self.req_use("|| ( a? ( b ) )"))) == ["a? ( b )"]

    def test_iter_conditionals(self):
        assert list(self.req_use("a").iter_conditionals()) == []
        assert list(self.req_use("( a )").iter_conditionals()) == []
        assert list(self.req_use("u? ( a )").iter_conditionals()) == ["u"]
        assert list(self.req_use("!u? ( a )").iter_conditionals()) == ["u"]
        assert list(self.req_use("|| ( a? ( b !c? ( d ) ) )").iter_conditionals()) == ["a", "c"]

    def test_iter_flatten(self):
        assert list(self.req_use("a").iter_flatten()) == ["a"]
        assert list(self.req_use("!a").iter_flatten()) == ["a"]
        assert list(self.req_use("( a )").iter_flatten()) == ["a"]
        assert list(self.req_use("|| ( a b )").iter_flatten()) == ["a", "b"]
        assert list(self.req_use("|| ( a? ( b ) )").iter_flatten()) == ["b"]

    def test_iter_recursive(self):
        assert list(map(str, self.req_use("a").iter_recursive())) == ["a"]
        assert list(map(str, self.req_use("!a").iter_recursive())) == ["!a"]
        assert list(map(str, self.req_use("( a )").iter_recursive())) == ["( a )", "a"]
        assert list(map(str, self.req_use("|| ( a b )").iter_recursive())) == ["|| ( a b )", "a", "b"]
        assert list(map(str, self.req_use("|| ( a? ( b ) )").iter_recursive())) == ["|| ( a? ( b ) )", "a? ( b )", "b"]

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
