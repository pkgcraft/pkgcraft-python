import textwrap

import pytest

from pkgcraft.config import Config
from pkgcraft.eapi import EAPIS
from pkgcraft.pkg import EbuildPkg
from pkgcraft.atom import Cpv, Version


class TestEbuildPkg:

    def test_init(self):
        with pytest.raises(RuntimeError, match="doesn't support manual construction"):
            EbuildPkg()

    def test_repr(self, repo):
        pkg = repo.create_pkg('cat/pkg-1')
        assert repr(pkg).startswith(f"<EbuildPkg 'cat/pkg-1' at 0x")

    def test_atom(self, repo):
        pkg = repo.create_pkg('cat/pkg-1')
        assert pkg.atom == Cpv('cat/pkg-1')

    def test_repo(self, repo):
        repo.create_ebuild('cat/pkg-1')
        config = Config()
        r = config.add_repo_path(repo.path)
        pkg = next(iter(r))
        assert pkg.repo == r
        # repo attribute allows recursion
        assert pkg == next(iter(pkg.repo))

    def test_eapi(self, repo):
        pkg = repo.create_pkg('cat/pkg-1', eapi='7')
        assert pkg.eapi is EAPIS['7']
        pkg = repo.create_pkg('cat/pkg-1', eapi='8')
        assert pkg.eapi is EAPIS['8']

    def test_version(self, repo):
        pkg = repo.create_pkg('cat/pkg-1')
        assert pkg.version == Version('1')
        pkg = repo.create_pkg('cat/pkg-2')
        assert pkg.version == Version('2')

    def test_path(self, repo):
        path = repo.create_ebuild()
        config = Config()
        r = config.add_repo_path(repo.path)
        pkg = next(iter(r))
        assert pkg.path == str(path)

    def test_ebuild(self, repo):
        pkg = repo.create_pkg()
        assert pkg.ebuild

    def test_description(self, repo):
        pkg = repo.create_pkg(description="desc")
        assert pkg.description == "desc"

    def test_slot(self, repo):
        pkg = repo.create_pkg(slot='1/2')
        assert pkg.slot == "1"

    def test_subslot(self, repo):
        pkg = repo.create_pkg()
        assert pkg.subslot == '0'
        pkg = repo.create_pkg(slot='1/2')
        assert pkg.subslot == '2'

    def test_depend(self, repo):
        pkg = repo.create_pkg()
        assert not pkg.depend

    def test_bdepend(self, repo):
        pkg = repo.create_pkg()
        assert not pkg.bdepend

    def test_idepend(self, repo):
        pkg = repo.create_pkg()
        assert not pkg.idepend

    def test_pdepend(self, repo):
        pkg = repo.create_pkg()
        assert not pkg.pdepend

    def test_rdepend(self, repo):
        pkg = repo.create_pkg()
        assert not pkg.rdepend

    def test_license(self, repo):
        pkg = repo.create_pkg()
        assert not pkg.license

    def test_required_use(self, repo):
        pkg = repo.create_pkg()
        assert not pkg.required_use

    def test_src_uri(self, repo):
        pkg = repo.create_pkg()
        assert not pkg.src_uri

    def test_homepage(self, repo):
        # none
        pkg = repo.create_pkg()
        assert not pkg.homepage

        # single
        pkg = repo.create_pkg(homepage='https://a.com')
        assert len(pkg.homepage) == 1

        # multiple
        pkg = repo.create_pkg(homepage='https://a.com https://b.com')
        assert pkg.homepage == ('https://a.com', 'https://b.com')

    def test_keywords(self, repo):
        # empty
        pkg = repo.create_pkg()
        assert not pkg.keywords

        # multiple
        pkg = repo.create_pkg(keywords='amd64 ~arm64')
        assert pkg.keywords == ('amd64', '~arm64')

    def test_iuse(self, repo):
        # empty
        pkg = repo.create_pkg()
        assert not pkg.iuse

        # multiple
        pkg = repo.create_pkg(iuse='a b c')
        assert pkg.iuse == frozenset(['a', 'b', 'c'])

    def test_inherits(self, repo):
        # empty
        pkg = repo.create_pkg()
        assert not pkg.inherit
        assert not pkg.inherited

    def test_long_description(self, repo):
        # none
        pkg = repo.create_pkg()
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
        pkg = repo.create_pkg()
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

        # multiple
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

        # verify hashing support
        assert len(set(pkg.maintainers)) == 3

    def test_upstreams(self, repo):
        # none
        pkg = repo.create_pkg()
        assert not pkg.upstreams

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
        assert not pkg.upstreams

        # multiple
        config = Config()
        r = config.add_repo_path(repo.path)
        path = repo.create_ebuild("cat/pkg-1")
        with open(path.parent / "metadata.xml", "w") as f:
            f.write(textwrap.dedent("""
                <pkgmetadata>
                    <upstream>
                        <remote-id type="github">pkgcraft/pkgcraft</remote-id>
                        <remote-id type="pypi">pkgcraft</remote-id>
                    </upstream>
                </pkgmetadata>
            """))
        pkg = next(iter(r))
        assert len(pkg.upstreams) == 2
        assert str(pkg.upstreams[0]) == "github: pkgcraft/pkgcraft"
        assert repr(pkg.upstreams[0]) == "<Upstream 'github: pkgcraft/pkgcraft'>"
        assert str(pkg.upstreams[1]) == "pypi: pkgcraft"
        assert repr(pkg.upstreams[1]) == "<Upstream 'pypi: pkgcraft'>"

        # verify hashing support
        assert len(set(pkg.upstreams)) == 2
