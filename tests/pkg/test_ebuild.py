import pytest

from pkgcraft.config import Config
from pkgcraft.pkg import EbuildPkg
from pkgcraft.atom import Cpv, Version


class TestEbuildPkg:

    def test_init(self):
        with pytest.raises(RuntimeError, match="doesn't support manual construction"):
            EbuildPkg()

    def test_repr(self, repo):
        repo.create_ebuild("cat/pkg-1")
        config = Config()
        r = config.add_repo_path(repo.path)
        pkg = next(iter(r))
        assert repr(pkg).startswith(f"<EbuildPkg 'cat/pkg-1' at 0x")

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

    def test_homepage(self, repo):
        config = Config()
        r = config.add_repo_path(repo.path)

        # single
        repo.create_ebuild("cat/pkg-1")
        pkg = next(iter(r))
        assert len(pkg.homepage) == 1

        # multiple
        repo.create_ebuild("cat/pkg-1", homepage="https://a.com https://b.com")
        pkg = next(iter(r))
        assert pkg.homepage == ("https://a.com", "https://b.com")

    def test_keywords(self, repo):
        config = Config()
        r = config.add_repo_path(repo.path)

        # empty
        repo.create_ebuild("cat/pkg-1")
        pkg = next(iter(r))
        assert pkg.keywords == ()

        # multiple
        repo.create_ebuild("cat/pkg-1", keywords="amd64 ~arm64")
        pkg = next(iter(r))
        assert pkg.keywords == ("amd64", "~arm64")

    def test_iuse(self, repo):
        config = Config()
        r = config.add_repo_path(repo.path)

        # empty
        repo.create_ebuild("cat/pkg-1")
        pkg = next(iter(r))
        assert pkg.iuse == ()

        # multiple
        repo.create_ebuild("cat/pkg-1", iuse="a b c")
        pkg = next(iter(r))
        assert pkg.iuse == ("a", "b", "c")
