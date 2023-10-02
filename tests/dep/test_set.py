import pytest

from pkgcraft.dep import Dependencies
from pkgcraft.eapi import EAPI8
from pkgcraft.error import InvalidDep


class TestDependencies:
    def test_parse(self):
        dep1 = Dependencies("a/b")
        assert str(dep1) == "a/b"
        assert repr(dep1).startswith("<Dependencies 'a/b' at 0x")
        dep2 = Dependencies("a/b", EAPI8)
        assert dep1 == dep2

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
