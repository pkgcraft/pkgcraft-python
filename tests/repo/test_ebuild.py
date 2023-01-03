from pathlib import Path

import pytest

from pkgcraft.atom import Cpv

from .base import BaseRepoTests


@pytest.fixture
def make_repo(make_ebuild_repo):
    return make_ebuild_repo


@pytest.fixture
def repo(ebuild_repo):
    return ebuild_repo


class TestEbuildRepo(BaseRepoTests):

    def test_contains_path(self, make_ebuild_repo):
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
