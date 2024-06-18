import pickle

import pytest

from pkgcraft.dep import *
from pkgcraft.error import InvalidCpn
from pkgcraft.restrict import Restrict


class TestCpn:
    def test_creation(self):
        cpn = Cpn("cat/pkg")
        assert cpn.category == "cat"
        assert cpn.package == "pkg"
        assert str(cpn) == "cat/pkg"
        assert "Cpn 'cat/pkg' at 0x" in repr(cpn)

        # invalid values
        for s in ("invalid", "cat-1", "cat/pkg-1", "=cat/pkg-1"):
            with pytest.raises(InvalidCpn, match=f"invalid cpn: {s}"):
                Cpn(s)

        # invalid types
        for obj in [None, object()]:
            with pytest.raises(TypeError):
                Cpn(obj)

    def test_parse(self):
        assert Cpn.parse("cat/pkg")

        # invalid
        for s in ("cat", "cat/pkg-1", "=cat/pkg-1"):
            assert not Cpn.parse(s)
            with pytest.raises(InvalidCpn, match=f"invalid cpn: {s}"):
                Cpn.parse(s, raised=True)

        # invalid args
        for obj in [object(), None]:
            with pytest.raises(TypeError):
                Cpn.parse(obj)

    def test_matches(self):
        cpn = Cpn("cat/pkg")
        r = Restrict(cpn)
        assert cpn.matches(r)
        assert not cpn.matches(~r)

    def test_cmp(self):
        cpn1 = Cpn("a/b")
        cpn2 = Cpn("b/c")
        obj = object()

        assert cpn1 < cpn2
        with pytest.raises(TypeError):
            assert cpn1 < obj

        assert cpn1 <= cpn2
        assert cpn2 <= cpn2
        with pytest.raises(TypeError):
            assert cpn1 <= obj

        assert cpn1 == cpn1
        assert not cpn1 == obj

        assert cpn1 != cpn2
        assert cpn1 != obj

        assert cpn2 >= cpn1
        assert cpn2 >= cpn2
        with pytest.raises(TypeError):
            assert cpn2 >= obj

        assert cpn2 > cpn1
        with pytest.raises(TypeError):
            assert cpn2 > obj

    def test_hash(self):
        cpn1 = Cpn("a/b")
        cpn2 = Cpn("a/b")
        cpn3 = Cpn("b/c")
        assert len({cpn1, cpn2}) == 1
        assert len({cpn1, cpn2, cpn3}) == 2

    def test_pickle(self):
        cpn1 = Cpn("cat/pkg")
        cpn2 = pickle.loads(pickle.dumps(cpn1))
        assert cpn1 == cpn2
