import pytest

from pkgcraft.config import Config
from pkgcraft.error import PkgcraftError
from pkgcraft.pkg import EbuildPkg


class TestEbuildPkg:

    def test_init(self):
        with pytest.raises(PkgcraftError, match=f"doesn't support regular creation"):
            EbuildPkg()

    def test_description(self, repo):
        path = repo.path
        config = Config()
        r = config.add_repo(path)
        repo.create_ebuild("cat/pkg-1", description="desc")
        pkg = next(iter(r))
        assert pkg.description == "desc"

    def test_slot(self, repo):
        path = repo.path
        config = Config()
        r = config.add_repo(path)
        repo.create_ebuild("cat/pkg-1", slot="1")
        pkg = next(iter(r))
        assert pkg.slot == "1"
