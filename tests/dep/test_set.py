import pytest

from pkgcraft.dep import *
from pkgcraft.eapi import EAPI8
from pkgcraft.error import InvalidDep


class TestDependencies:
    def test_parse(self):
        d1 = Dependencies("a/b")
        assert str(d1) == "a/b"
        assert repr(d1).startswith("<Dependencies 'a/b' at 0x")
        d2 = Dependencies("a/b", EAPI8)
        assert d1 == d2

        with pytest.raises(InvalidDep):
            Dependencies("a/b::repo", EAPI8)

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
