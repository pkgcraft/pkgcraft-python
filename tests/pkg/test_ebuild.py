import pytest

from pkgcraft.config import Config
from pkgcraft.error import PkgcraftError
from pkgcraft.pkg import EbuildPkg
from pkgcraft.atom import Cpv, Version


class TestEbuildPkg:

    def test_init(self):
        with pytest.raises(PkgcraftError, match=f"doesn't support regular creation"):
            EbuildPkg()

    def test_atom(self, repo):
        repo.create_ebuild("cat/pkg-1")
        config = Config()
        r = config.add_repo_path(repo.path)
        pkg = next(iter(r))
        assert pkg.atom == Cpv("cat/pkg-1")

    def test_repo(self, repo):
        repo.create_ebuild("cat/pkg-1")
        config = Config()
        r = config.add_repo_path(repo.path)
        pkg = next(iter(r))
        assert pkg.repo == r
        # repo attribute allows recursion
        assert pkg == next(iter(pkg.repo))

    def test_eapi(self, repo):
        repo.create_ebuild("cat/pkg-1", eapi="7")
        repo.create_ebuild("cat/pkg-2", eapi="8")
        config = Config()
        r = config.add_repo_path(repo.path)
        pkgs = iter(r)
        assert next(pkgs).eapi == "7"
        assert next(pkgs).eapi == "8"

    def test_version(self, repo):
        repo.create_ebuild("cat/pkg-1")
        repo.create_ebuild("cat/pkg-2")
        config = Config()
        r = config.add_repo_path(repo.path)
        pkgs = iter(r)
        assert next(pkgs).version == Version('1')
        assert next(pkgs).version == Version('2')

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
