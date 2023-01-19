import pytest

from pkgcraft.atom import Atom, Cpv
from pkgcraft.error import InvalidRestrict
from pkgcraft.restrict import Restrict


class TestRestrict:
    def test_invalid(self):
        # incompatible type
        with pytest.raises(TypeError):
            Restrict(object())

        # invalid restriction string
        with pytest.raises(InvalidRestrict):
            Restrict("a b c")

    def test_valid(self, fake_repo):
        pkg1 = fake_repo.create_pkg("cat/pkg-1")
        pkg2 = fake_repo.create_pkg("cat/pkg-2")

        # cpv string
        r = Restrict("cat/pkg-1")
        assert list(fake_repo.iter_restrict(r)) == [pkg1]
        # cpv
        r = Restrict(Cpv("cat/pkg-1"))
        assert list(fake_repo.iter_restrict(r)) == [pkg1]
        # atom string
        r = Restrict("=cat/pkg-1")
        assert list(fake_repo.iter_restrict(r)) == [pkg1]
        # atom
        r = Restrict(Atom("=cat/pkg-1"))
        assert list(fake_repo.iter_restrict(r)) == [pkg1]

    def test_dep(self, fake_repo):
        with pytest.raises(InvalidRestrict):
            Restrict.dep("cat/pkg#")

        r = Restrict.dep("cat/pkg")
        pkg = fake_repo.create_pkg("cat/pkg-1")
        assert r.matches(pkg)

    def test_pkg(self, ebuild_repo):
        with pytest.raises(InvalidRestrict):
            Restrict.pkg('description ~= "fake"')

        r = Restrict.pkg('description =~ "fake"')
        pkg = ebuild_repo.create_pkg("cat/pkg-1", description="fake pkg")
        assert r.matches(pkg)

    def test_matches(self, fake_repo):
        r = Restrict("cat/pkg")
        pkg1 = fake_repo.create_pkg("cat/pkg-1")
        pkg2 = fake_repo.create_pkg("a/b-1")

        # Cpv objects
        assert r.matches(Cpv("cat/pkg-1"))
        assert not r.matches(Cpv("a/b-1"))
        # Atom objects
        assert r.matches(Atom(">=cat/pkg-1"))
        assert not r.matches(Atom("<a/b-1"))
        # Pkg objects
        assert r.matches(pkg1)
        assert not r.matches(pkg2)

        # unsupported types
        for obj in (object(), None):
            with pytest.raises(TypeError):
                assert r.matches(obj)

    def test_eq_and_hash(self, fake_repo):
        r1 = Restrict("cat/pkg-1")
        assert r1 == r1
        r2 = Restrict(Cpv("cat/pkg-1"))
        assert r1 == r2
        assert r2 == r1
        assert len({r1, r2}) == 1

        pkg1 = fake_repo.create_pkg("cat/pkg-1")
        r3 = Restrict(pkg1)
        pkg2 = fake_repo.create_pkg("cat/pkg-2")
        r4 = Restrict(pkg2)
        assert r3 != r4
        assert len({r3, r4}) == 2
        assert r2 != r3
        assert len({r2, r3}) == 2

    def test_logic_ops(self, fake_repo):
        pkg1 = fake_repo.create_pkg("cat/pkg-1")
        pkg2 = fake_repo.create_pkg("cat/pkg-2")

        r1 = Restrict("cat/pkg-1")
        r2 = Restrict("cat/pkg-2")
        assert list(fake_repo.iter_restrict(r1)) == [pkg1]
        assert list(fake_repo.iter_restrict(r2)) == [pkg2]
        assert list(fake_repo.iter_restrict(~r1)) == [pkg2]
        assert list(fake_repo.iter_restrict(~r2)) == [pkg1]
        assert list(fake_repo.iter_restrict(r1 & r2)) == []
        assert list(fake_repo.iter_restrict(r1 | r2)) == [pkg1, pkg2]
        assert list(fake_repo.iter_restrict(r1 ^ r2)) == [pkg1, pkg2]
        assert list(fake_repo.iter_restrict(~(r1 & r2))) == [pkg1, pkg2]
        assert list(fake_repo.iter_restrict(~(r1 | r2))) == []
        assert list(fake_repo.iter_restrict(~(r1 ^ r2))) == []

        r1 = Restrict("cat/pkg")
        r2 = Restrict("cat/pkg-2")
        assert list(fake_repo.iter_restrict(r1)) == [pkg1, pkg2]
        assert list(fake_repo.iter_restrict(r2)) == [pkg2]
        assert list(fake_repo.iter_restrict(~r1)) == []
        assert list(fake_repo.iter_restrict(~r2)) == [pkg1]
        assert list(fake_repo.iter_restrict(r1 & r2)) == [pkg2]
        assert list(fake_repo.iter_restrict(r1 | r2)) == [pkg1, pkg2]
        assert list(fake_repo.iter_restrict(r1 ^ r2)) == [pkg1]
        assert list(fake_repo.iter_restrict(~(r1 & r2))) == [pkg1]
        assert list(fake_repo.iter_restrict(~(r1 | r2))) == []
        assert list(fake_repo.iter_restrict(~(r1 ^ r2))) == [pkg2]
