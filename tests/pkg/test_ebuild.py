import pytest

from pkgcraft.config import Config
from pkgcraft.error import PkgcraftError
from pkgcraft.pkg import EbuildPkg


class TestEbuildPkg:

    def test_init(self):
        with pytest.raises(PkgcraftError, match=f"doesn't support regular creation"):
            EbuildPkg()

    def test_ebuild(self, repo):
        repo.create_ebuild("cat/pkg-1")
        config = Config()
        r = config.add_repo_path(repo.path)
        pkg = next(iter(r))
        assert pkg.ebuild

    def test_description(self, repo):
        repo.create_ebuild("cat/pkg-1", description="desc")
        config = Config()
        r = config.add_repo_path(repo.path)
        pkg = next(iter(r))
        assert pkg.description == "desc"

    def test_slot(self, repo):
        repo.create_ebuild("cat/pkg-1", slot="1")
        config = Config()
        r = config.add_repo_path(repo.path)
        pkg = next(iter(r))
        assert pkg.slot == "1"
