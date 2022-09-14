import pytest

from pkgcraft.atom import Cpv
from pkgcraft.config import Config
from pkgcraft.error import InvalidRestrict, PkgcraftError
from pkgcraft.repo import EbuildRepo


class TestEbuildRepo:

    def test_init(self, raw_repo):
        config = Config()
        r = EbuildRepo(config, raw_repo.path)
        assert r.path == str(raw_repo.path)

    def test_masters(self, make_raw_repo):
        config = Config()
        # empty masters
        repo = make_raw_repo()
        r = config.add_repo_path(repo.path)
        assert not r.masters

        # non-empty masters
        overlay = make_raw_repo(masters=[r.path])
        o = config.add_repo_path(overlay.path)
        assert o.masters == (r,)

    def test_iter(self, repo):
        # calling next() directly on a repo object fails
        with pytest.raises(TypeError, match="object is not an iterator"):
            next(repo)

        # empty repo
        assert not list(iter(repo))

        # single pkg
        pkg1 = repo.create_pkg('cat/pkg-1')
        assert list(iter(repo)) == [pkg1]

        # multiple pkgs
        pkg2 = repo.create_pkg('cat/pkg-2')
        assert list(iter(repo)) == [pkg1, pkg2]

    def test_iter_restrict(self, repo):
        # non-None argument required
        with pytest.raises(TypeError, match='must not be None'):
            repo.iter_restrict(None)

        # unsupported object type
        with pytest.raises(TypeError, match='unsupported restriction type'):
            list(repo.iter_restrict(repo))

        cpv = Cpv('cat/pkg-1')

        # empty repo -- no matches
        assert not list(repo.iter_restrict(cpv))

        pkg1 = repo.create_pkg('cat/pkg-1')
        pkg2 = repo.create_pkg('cat/pkg-2')

        # non-empty repo -- no matches
        nonexistent = Cpv('nonexistent/pkg-1')
        assert not list(repo.iter_restrict(nonexistent))

        # single match via Cpv
        assert list(repo.iter_restrict(cpv)) == [pkg1]

        # single match via package
        assert list(repo.iter_restrict(pkg1)) == [pkg1]

        # multiple matches via restriction glob
        assert list(repo.iter_restrict('cat/*')) == [pkg1, pkg2]

        # invalid restriction string
        with pytest.raises(InvalidRestrict):
            list(repo.iter_restrict('-'))
