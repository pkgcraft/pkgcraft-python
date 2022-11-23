import pytest

from pkgcraft.atom import Cpv, Atom
from pkgcraft.error import InvalidRestrict
from pkgcraft.restrict import Restrict


class TestRestrict:

    def test_invalid(self):
        # incompatible type
        with pytest.raises(TypeError):
            Restrict(object())

        # invalid restriction string
        with pytest.raises(InvalidRestrict):
            Restrict('a b c')

    def test_valid(self, fake_repo):
        pkg1 = fake_repo.create_pkg('cat/pkg-1')
        pkg2 = fake_repo.create_pkg('cat/pkg-2')

        # cpv string
        r = Restrict('cat/pkg-1')
        assert list(fake_repo.iter_restrict(r)) == [pkg1]
        # cpv
        r = Restrict(Cpv('cat/pkg-1'))
        assert list(fake_repo.iter_restrict(r)) == [pkg1]
        # atom string
        r = Restrict('=cat/pkg-1')
        assert list(fake_repo.iter_restrict(r)) == [pkg1]
        # atom
        r = Restrict(Atom('=cat/pkg-1'))
        assert list(fake_repo.iter_restrict(r)) == [pkg1]

    def test_logic_ops(self, fake_repo):
        pkg1 = fake_repo.create_pkg('cat/pkg-1')
        pkg2 = fake_repo.create_pkg('cat/pkg-2')

        r1 = Restrict('cat/pkg-1')
        r2 = Restrict('cat/pkg-2')
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

        r1 = Restrict('cat/pkg')
        r2 = Restrict('cat/pkg-2')
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
