import pytest

from pkgcraft.atom import Cpv
from pkgcraft.config import Config
from pkgcraft.error import InvalidRestrict, PkgcraftError
from pkgcraft.repo import EbuildRepo


class TestEbuildRepo:

    def test_init(self):
        with pytest.raises(RuntimeError, match="doesn't support manual construction"):
            EbuildRepo()

    def test_masters(self, make_repo):
        # empty masters
        repo = make_repo()
        config = Config()
        r = config.add_repo_path(repo.path)
        assert not r.masters

        # non-empty masters
        overlay = make_repo(masters=[repo.path])
        o = config.add_repo_path(overlay.path)
        assert o.masters == (r,)

    def test_iter(self, repo):
        path = repo.path
        config = Config()
        r = config.add_repo_path(path)

        # iterating on a raw repo object fails
        with pytest.raises(TypeError, match="object is not an iterator"):
            next(r)

        # empty repo
        assert not list(iter(r))

        # single pkg
        pkg1 = repo.create_pkg('cat/pkg-1')
        assert list(iter(r)) == [pkg1]

        # multiple pkgs
        pkg2 = repo.create_pkg('cat/pkg-2')
        assert list(iter(r)) == [pkg1, pkg2]

    def test_iter_restrict(self, repo):
        path = repo.path
        config = Config()
        r = config.add_repo_path(path)

        # non-None argument required
        with pytest.raises(TypeError, match='must not be None'):
            r.iter_restrict(None)

        # unsupported object type
        with pytest.raises(TypeError, match='unsupported restriction type'):
            list(r.iter_restrict(r))

        cpv = Cpv('cat/pkg-1')

        # empty repo -- no matches
        assert not list(r.iter_restrict(cpv))

        pkg1 = repo.create_pkg('cat/pkg-1')
        pkg2 = repo.create_pkg('cat/pkg-2')

        # non-empty repo -- no matches
        nonexistent = Cpv('nonexistent/pkg-1')
        assert not list(r.iter_restrict(nonexistent))

        # single match via Cpv
        assert list(r.iter_restrict(cpv)) == [pkg1]

        # single match via package
        assert list(r.iter_restrict(pkg1)) == [pkg1]

        # multiple matches via restriction glob
        assert list(r.iter_restrict('cat/*')) == [pkg1, pkg2]

        # invalid restriction string
        with pytest.raises(InvalidRestrict):
            list(r.iter_restrict('-'))
