import textwrap

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
        assert str(next(pkgs).eapi) == "7"
        assert str(next(pkgs).eapi) == "8"

    def test_version(self, repo):
        repo.create_ebuild("cat/pkg-1")
        repo.create_ebuild("cat/pkg-2")
        config = Config()
        r = config.add_repo_path(repo.path)
        pkgs = iter(r)
        assert next(pkgs).version == Version('1')
        assert next(pkgs).version == Version('2')

    def test_path(self, repo):
        path = repo.create_ebuild("cat/pkg-1")
        config = Config()
        r = config.add_repo_path(repo.path)
        pkg = next(iter(r))
        assert pkg.path == str(path)

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
        repo.create_ebuild("cat/pkg-1", slot="1/2")
        config = Config()
        r = config.add_repo_path(repo.path)
        pkg = next(iter(r))
        assert pkg.slot == "1"

    def test_subslot(self, repo):
        repo.create_ebuild("cat/pkg-1", slot="1/2")
        config = Config()
        r = config.add_repo_path(repo.path)
        pkg = next(iter(r))
        assert pkg.subslot == "2"

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
        assert not pkg.keywords

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
        assert not pkg.iuse

        # multiple
        repo.create_ebuild("cat/pkg-1", iuse="a b c")
        pkg = next(iter(r))
        assert pkg.iuse == frozenset(["a", "b", "c"])

    def test_long_description(self, repo):
        # none
        config = Config()
        r = config.add_repo_path(repo.path)
        repo.create_ebuild("cat/pkg-1")
        pkg = next(iter(r))
        assert pkg.long_description is None

        # invalid
        config = Config()
        r = config.add_repo_path(repo.path)
        path = repo.create_ebuild("cat/pkg-1")
        with open(path.parent / "metadata.xml", "w") as f:
            f.write(textwrap.dedent("""
                <pkgmetadata>
                    <longdescription>
                        long description
                    </longdescription>
                </pkg>
            """))
        pkg = next(iter(r))
        assert pkg.long_description is None

        # empty
        config = Config()
        r = config.add_repo_path(repo.path)
        path = repo.create_ebuild("cat/pkg-1")
        with open(path.parent / "metadata.xml", "w") as f:
            f.write(textwrap.dedent("""
                <pkgmetadata>
                    <longdescription>
                    </longdescription>
                </pkgmetadata>
            """))
        pkg = next(iter(r))
        assert pkg.long_description == ""

        # exists
        config = Config()
        r = config.add_repo_path(repo.path)
        path = repo.create_ebuild("cat/pkg-1")
        with open(path.parent / "metadata.xml", "w") as f:
            f.write(textwrap.dedent("""
                <pkgmetadata>
                    <longdescription>
                        long description
                    </longdescription>
                </pkgmetadata>
            """))
        pkg = next(iter(r))
        assert pkg.long_description == "long description"

    def test_maintainers(self, repo):
        # none
        config = Config()
        r = config.add_repo_path(repo.path)
        repo.create_ebuild("cat/pkg-1")
        pkg = next(iter(r))
        assert not pkg.maintainers

        # invalid
        config = Config()
        r = config.add_repo_path(repo.path)
        path = repo.create_ebuild("cat/pkg-1")
        with open(path.parent / "metadata.xml", "w") as f:
            f.write(textwrap.dedent("""
                <pkgmetadata>
                </pkg>
            """))
        pkg = next(iter(r))
        assert not pkg.maintainers

        # single
        config = Config()
        r = config.add_repo_path(repo.path)
        path = repo.create_ebuild("cat/pkg-1")
        with open(path.parent / "metadata.xml", "w") as f:
            f.write(textwrap.dedent("""
                <pkgmetadata>
                    <maintainer type="person">
                        <email>a.person@email.com</email>
                        <name>A Person</name>
                    </maintainer>
                    <maintainer type="project" proxied="proxy">
                        <email>a.project@email.com</email>
                    </maintainer>
                    <maintainer type="person" proxied="yes">
                        <email>b.person@email.com</email>
                        <name>B Person</name>
                        <description>Another Person</description>
                    </maintainer>
                </pkgmetadata>
            """))
        pkg = next(iter(r))
        assert len(pkg.maintainers) == 3
        assert str(pkg.maintainers[0]) == "A Person <a.person@email.com>"
        assert repr(pkg.maintainers[0]) == "<Maintainer 'a.person@email.com'>"
        assert pkg.maintainers[0].maint_type == "person"
        assert str(pkg.maintainers[1]) == "a.project@email.com"
        assert repr(pkg.maintainers[1]) == "<Maintainer 'a.project@email.com'>"
        assert pkg.maintainers[1].maint_type == "project"
        assert pkg.maintainers[1].proxied == "proxy"
        assert str(pkg.maintainers[2]) == "B Person <b.person@email.com> (Another Person)"
        assert repr(pkg.maintainers[2]) == "<Maintainer 'b.person@email.com'>"
        assert pkg.maintainers[2].maint_type == "person"
        assert pkg.maintainers[2].proxied == "yes"
