from pathlib import Path

import pytest

from pkgcraft.atom import Cpv
from pkgcraft.error import InvalidRestrict

from .base import BaseRepoTests


@pytest.fixture
def make_repo(make_ebuild_repo):
    return make_ebuild_repo


@pytest.fixture
def repo(ebuild_repo):
    return ebuild_repo


class TestEbuildRepo(BaseRepoTests):

    def test_contains(self, make_ebuild_repo):
        r1 = make_ebuild_repo()
        r2 = make_ebuild_repo()
        pkg1 = r1.create_pkg('cat/pkg-1')
        pkg2 = r2.create_pkg('cat/pkg-1')

        # Path objects
        assert Path('cat') in r1
        assert Path('cat/pkg') in r1
        assert Path('cat/pkg2') not in r1
        assert pkg1.path in r1
        assert pkg2.path not in r1
        assert pkg1.path not in r2
        assert pkg2.path in r2

    def test_masters(self, config, make_raw_ebuild_repo):
        # empty masters
        repo = make_raw_ebuild_repo()
        r = config.add_repo(repo.path)
        assert not r.masters

        # non-empty masters
        overlay = make_raw_ebuild_repo(masters=[r.path])
        o = config.add_repo(overlay.path)
        assert o.masters == (r,)

    def test_iter(self, ebuild_repo):
        # calling next() directly on a repo object fails
        with pytest.raises(TypeError):
            next(ebuild_repo)

        # empty repo
        assert not list(ebuild_repo)

        # single pkg
        pkg1 = ebuild_repo.create_pkg('cat/pkg-1')
        assert list(ebuild_repo) == [pkg1]

        # multiple pkgs
        pkg2 = ebuild_repo.create_pkg('cat/pkg-2')
        assert list(ebuild_repo) == [pkg1, pkg2]

    def test_iter_restrict(self, ebuild_repo):
        # non-None argument required
        with pytest.raises(TypeError):
            ebuild_repo.iter_restrict(None)

        # unsupported object type
        with pytest.raises(TypeError):
            list(ebuild_repo.iter_restrict(object()))

        cpv = Cpv('cat/pkg-1')

        # empty repo -- no matches
        assert not list(ebuild_repo.iter_restrict(cpv))

        pkg1 = ebuild_repo.create_pkg('cat/pkg-1')
        pkg2 = ebuild_repo.create_pkg('cat/pkg-2')

        # non-empty repo -- no matches
        nonexistent = Cpv('nonexistent/pkg-1')
        assert not list(ebuild_repo.iter_restrict(nonexistent))

        # single match via Cpv
        assert list(ebuild_repo.iter_restrict(cpv)) == [pkg1]

        # single match via package
        assert list(ebuild_repo.iter_restrict(pkg1)) == [pkg1]

        # multiple matches via restriction glob
        assert list(ebuild_repo.iter_restrict('cat/*')) == [pkg1, pkg2]

        # invalid restriction string
        with pytest.raises(InvalidRestrict):
            list(ebuild_repo.iter_restrict('-'))
