import pytest

from pkgcraft.atom import Cpv
from pkgcraft.config import Config
from pkgcraft.error import PkgcraftError
from pkgcraft.repo import EbuildRepo


class TestEbuildRepo:

    def test_init(self):
        with pytest.raises(PkgcraftError, match=f"doesn't support regular creation"):
            EbuildRepo()

    def test_category_dirs(self, repo):
        path = repo.path
        config = Config()
        r = config.add_repo_path(path)

        # empty repo
        assert r.category_dirs == ()

        # create ebuild
        repo.create_ebuild("cat1/pkga-1")
        assert r.category_dirs == ('cat1',)

        # create new ebuild version
        repo.create_ebuild("cat1/pkga-2")
        assert r.category_dirs == ('cat1',)

        # create new pkg
        repo.create_ebuild("cat1/pkgb-1")
        assert r.category_dirs == ('cat1',)

        # create new pkg in new category
        repo.create_ebuild("cat2/pkga-1")
        assert r.category_dirs == ('cat1', 'cat2')

    def test_masters(self, make_repo):
        # empty masters
        repo = make_repo()
        config = Config()
        r = config.add_repo_path(repo.path)
        assert r.masters == ()

        # non-empty masters
        overlay = make_repo(masters=[repo.path])
        o = config.add_repo_path(overlay.path)
        assert o.masters == (r,)

    def test_iter(self, repo):
        path = repo.path
        config = Config()
        r = config.add_repo_path(path)

        # iterating on a raw repo object fails
        with pytest.raises(TypeError, match=f"object is not an iterator"):
            next(r)

        # empty repo
        assert not list(iter(r))

        # single pkg
        repo.create_ebuild("cat/pkg-1")
        pkgs = iter(r)
        assert [str(x.atom) for x in pkgs] == ['cat/pkg-1']

        # multiple pkgs
        repo.create_ebuild("cat/pkg-2")
        pkgs = iter(r)
        assert [str(x.atom) for x in pkgs] == ['cat/pkg-1', 'cat/pkg-2']

    def test_iter_restrict(self, repo):
        path = repo.path
        config = Config()
        r = config.add_repo_path(path)

        # unsupported object type
        with pytest.raises(TypeError, match="unsupported restriction type"):
            list(r.iter_restrict(r))

        cpv = Cpv('cat/pkg-1')

        # empty repo -- no matches
        assert not list(r.iter_restrict(cpv))

        repo.create_ebuild("cat/pkg-1")
        repo.create_ebuild("cat/pkg-2")

        # non-empty repo -- no matches
        nonexistent = Cpv('nonexistent/pkg-1')
        assert not list(r.iter_restrict(nonexistent))

        # single match via Cpv
        pkgs = list(r.iter_restrict(cpv))
        assert [str(x.atom) for x in pkgs] == ['cat/pkg-1']

        # single match via package
        pkgs = r.iter_restrict(pkgs[0])
        assert [str(x.atom) for x in pkgs] == ['cat/pkg-1']

        # multiple matches via restriction glob
        pkgs = r.iter_restrict('cat/*')
        assert [str(x.atom) for x in pkgs] == ['cat/pkg-1', 'cat/pkg-2']
