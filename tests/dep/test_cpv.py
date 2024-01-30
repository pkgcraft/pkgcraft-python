import pickle

import pytest

from pkgcraft.dep import *
from pkgcraft.error import InvalidCpv
from pkgcraft.restrict import Restrict

from ..misc import TEST_DATA


class TestCpv:
    def test_creation(self):
        cpv = Cpv("cat/pkg-1-r2")
        assert cpv.category == "cat"
        assert cpv.package == "pkg"
        assert cpv.version == Version("1-r2")
        assert cpv.revision == Revision("2")
        assert cpv.p == "pkg-1"
        assert cpv.pf == "pkg-1-r2"
        assert cpv.pr == "r2"
        assert cpv.pv == "1"
        assert cpv.pvr == "1-r2"
        assert cpv.cpn == Cpn("cat/pkg")
        assert str(cpv) == "cat/pkg-1-r2"
        assert "Cpv 'cat/pkg-1-r2' at 0x" in repr(cpv)

        # invalid args
        for obj in [None, object()]:
            with pytest.raises(TypeError):
                Cpv(obj)

    def test_parse(self):
        assert Cpv.parse("cat/pkg-1")

        # invalid
        for s in ("cat", "cat/pkg", "=cat/pkg-1"):
            assert not Cpv.parse(s)
            with pytest.raises(InvalidCpv, match=f"invalid cpv: {s}"):
                Cpv.parse(s, raised=True)

        # invalid args
        for obj in [object(), None]:
            with pytest.raises(TypeError):
                Cpv.parse(obj)

    def test_matches(self):
        cpv = Cpv("cat/pkg-1")
        r = Restrict(cpv)
        assert cpv.matches(r)
        assert not cpv.matches(~r)

    def test_invalid(self):
        for s in ("invalid", "cat-1", "cat/pkg", "=cat/pkg-1"):
            with pytest.raises(InvalidCpv, match=f"invalid cpv: {s}"):
                Cpv(s)

    def test_invalid_arg_type(self):
        for obj in (object(), None):
            with pytest.raises(TypeError):
                Cpv(obj)

    def test_cmp(self):
        cpv1 = Cpv("cat/pkg-1")
        cpv2 = Cpv("cat/pkg-2")
        obj = object()

        assert cpv1 < cpv2
        with pytest.raises(TypeError):
            assert cpv1 < obj

        assert cpv1 <= cpv2
        assert cpv2 <= cpv2
        with pytest.raises(TypeError):
            assert cpv1 <= obj

        assert cpv1 == cpv1
        assert not cpv1 == obj

        assert cpv1 != cpv2
        assert cpv1 != obj

        assert cpv2 >= cpv1
        assert cpv2 >= cpv2
        with pytest.raises(TypeError):
            assert cpv2 >= obj

        assert cpv2 > cpv1
        with pytest.raises(TypeError):
            assert cpv2 > obj

    def test_intersects(self):
        cpv1 = Cpv("cat/pkg-1")
        cpv2 = Cpv("cat/pkg-2")

        # objects intersect themselves
        assert cpv1.intersects(cpv1)
        assert cpv2.intersects(cpv2)

        # unequal Cpvs
        assert not cpv1.intersects(cpv2)

        # unversioned Dep
        assert cpv1.intersects(Dep("cat/pkg"))

        # invalid type
        with pytest.raises(TypeError):
            cpv1.intersects(object())

    def test_hash(self):
        for d in TEST_DATA.toml("version.toml")["hashing"]:
            s = {Cpv(f"cat/pkg-{x}") for x in d["versions"]}
            length = 1 if d["equal"] else len(d["versions"])
            assert len(s) == length

    def test_pickle(self):
        cpv1 = Cpv("cat/pkg-1-r2")
        cpv2 = pickle.loads(pickle.dumps(cpv1))
        assert cpv1 == cpv2
