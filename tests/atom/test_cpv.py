import pickle

import pytest

from pkgcraft.atom import Cpv, Version
from pkgcraft.error import InvalidCpv
from pkgcraft.restrict import Restrict


class TestCpv:
    def test_init(self):
        a = Cpv("cat/pkg-1-r2")
        assert a.category == "cat"
        assert a.package == "pkg"
        assert a.version == Version("1-r2")
        assert a.revision == "2"
        assert a.cpn == "cat/pkg"
        assert str(a) == "cat/pkg-1-r2"
        assert repr(a).startswith("<Cpv 'cat/pkg-1-r2' at 0x")

    def test_matches(self):
        a = Cpv("cat/pkg-1")
        r = Restrict(a)
        assert a.matches(r)
        assert not a.matches(~r)

    def test_invalid(self):
        for s in ("invalid", "cat-1", "cat/pkg", "=cat/pkg-1"):
            with pytest.raises(InvalidCpv, match=f"invalid cpv: {s}"):
                Cpv(s)

    def test_invalid_arg_type(self):
        for obj in (object(), None):
            with pytest.raises(TypeError):
                Cpv(obj)

    def test_pickle(self):
        a = Cpv("cat/pkg-1-r2")
        b = pickle.loads(pickle.dumps(a))
        assert a == b
