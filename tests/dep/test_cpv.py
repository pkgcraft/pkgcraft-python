import pickle

import pytest

from pkgcraft.dep import Cpv, Dep, Version
from pkgcraft.error import InvalidCpv
from pkgcraft.restrict import Restrict


class TestCpv:
    def test_init(self):
        a = Cpv("cat/pkg-1-r2")
        assert a.category == "cat"
        assert a.package == "pkg"
        assert a.version == Version("1-r2")
        assert a.revision == "2"
        assert a.p == "pkg-1"
        assert a.pf == "pkg-1-r2"
        assert a.pr == "r2"
        assert a.pv == "1"
        assert a.pvr == "1-r2"
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

    def test_hash(self, testdata_toml):
        for d in testdata_toml["version.toml"]["hashing"]:
            s = {Cpv(f"cat/pkg-{x}") for x in d["versions"]}
            length = 1 if d["equal"] else len(d["versions"])
            assert len(s) == length

    def test_pickle(self):
        a = Cpv("cat/pkg-1-r2")
        b = pickle.loads(pickle.dumps(a))
        assert a == b
