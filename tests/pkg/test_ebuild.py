import os
import textwrap

import pytest

from pkgcraft.atom import Atom
from pkgcraft.eapi import EAPIS
from pkgcraft.error import PkgcraftError

from .base import BasePkgTests


@pytest.fixture
def make_repo(make_ebuild_repo):
    return make_ebuild_repo


@pytest.fixture
def repo(ebuild_repo):
    return ebuild_repo


@pytest.fixture
def pkg(repo):
    return repo.create_pkg("cat/pkg-1")


class TestEbuildPkg(BasePkgTests):
    def test_eapi(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1", eapi="7")
        assert pkg.eapi is EAPIS["7"]
        pkg = ebuild_repo.create_pkg("cat/pkg-1", eapi="8")
        assert pkg.eapi is EAPIS["8"]

    def test_path(self, ebuild_repo):
        path = ebuild_repo.create_ebuild()
        pkg = next(iter(ebuild_repo))
        assert pkg.path == path

    def test_ebuild(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert pkg.ebuild

        # missing file causes error
        os.remove(pkg.path)
        with pytest.raises(PkgcraftError):
            pkg.ebuild

    def test_description(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1", description="desc")
        assert pkg.description == "desc"

    def test_slot(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1", slot="1/2")
        assert pkg.slot == "1"

    def test_subslot(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert pkg.subslot == "0"
        pkg = ebuild_repo.create_pkg("cat/pkg-1", slot="1/2")
        assert pkg.subslot == "2"

    def test_dep_attrs(self, ebuild_repo):
        for attr in ("depend", "bdepend", "idepend", "pdepend", "rdepend"):
            pkg = ebuild_repo.create_pkg("cat/pkg-1")
            assert not getattr(pkg, attr)

            pkg = ebuild_repo.create_pkg("cat/pkg-1", **{attr: ""})
            val = getattr(pkg, attr)
            assert not getattr(pkg, attr)

            pkg = ebuild_repo.create_pkg("cat/pkg-1", **{attr: "cat/pkg"})
            val = getattr(pkg, attr)
            assert str(val) == "cat/pkg"
            assert list(val.iter_flatten()) == [Atom("cat/pkg")]
            assert list(map(str, val)) == ["cat/pkg"]

            pkg = ebuild_repo.create_pkg("cat/pkg-1", **{attr: "u? ( cat/pkg ) || ( a/b c/d )"})
            val = getattr(pkg, attr)
            assert str(val) == "u? ( cat/pkg ) || ( a/b c/d )"
            assert list(val.iter_flatten()) == [Atom("cat/pkg"), Atom("a/b"), Atom("c/d")]
            dep_restricts = list(val)
            assert list(map(str, dep_restricts)) == ["u? ( cat/pkg )", "|| ( a/b c/d )"]
            assert list(dep_restricts[1]) == [Atom("a/b"), Atom("c/d")]

            pkg = ebuild_repo.create_pkg("cat/pkg-1", **{attr: "u? ( a/b ) c/d"})
            val = getattr(pkg, attr)
            assert str(val) == "u? ( a/b ) c/d"
            assert list(val.iter_flatten()) == [Atom("a/b"), Atom("c/d")]
            dep_restricts = list(val)
            assert list(map(str, dep_restricts)) == ["u? ( a/b )", "c/d"]
            assert list(dep_restricts[1]) == [Atom("c/d")]

    def test_license(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert not pkg.license

        pkg = ebuild_repo.create_pkg("cat/pkg-1", license="BSD")
        assert str(pkg.license) == "BSD"
        assert list(pkg.license.iter_flatten()) == ["BSD"]

        pkg = ebuild_repo.create_pkg("cat/pkg-1", license="u? ( BSD )")
        assert str(pkg.license) == "u? ( BSD )"
        assert list(pkg.license.iter_flatten()) == ["BSD"]

    def test_properties(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert not pkg.properties

        pkg = ebuild_repo.create_pkg("cat/pkg-1", properties="live")
        assert str(pkg.properties) == "live"
        assert list(pkg.properties.iter_flatten()) == ["live"]

        pkg = ebuild_repo.create_pkg("cat/pkg-1", properties="u? ( live )")
        assert str(pkg.properties) == "u? ( live )"
        assert list(pkg.properties.iter_flatten()) == ["live"]

    def test_required_use(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert not pkg.required_use

        pkg = ebuild_repo.create_pkg("cat/pkg-1", required_use="use")
        assert str(pkg.required_use) == "use"
        assert list(pkg.required_use.iter_flatten()) == ["use"]

        pkg = ebuild_repo.create_pkg("cat/pkg-1", required_use="u1? ( u2 )")
        assert str(pkg.required_use) == "u1? ( u2 )"
        assert list(pkg.required_use.iter_flatten()) == ["u2"]

    def test_restrict(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert not pkg.restrict

        pkg = ebuild_repo.create_pkg("cat/pkg-1", restrict="fetch")
        assert str(pkg.restrict) == "fetch"
        assert list(pkg.restrict.iter_flatten()) == ["fetch"]

        pkg = ebuild_repo.create_pkg("cat/pkg-1", restrict="u? ( fetch )")
        assert str(pkg.restrict) == "u? ( fetch )"
        assert list(pkg.restrict.iter_flatten()) == ["fetch"]

    def test_src_uri(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert not pkg.src_uri

        pkg = ebuild_repo.create_pkg("cat/pkg-1", src_uri="https://a.com/b.tar.gz")
        assert str(pkg.src_uri) == "https://a.com/b.tar.gz"
        u = next(pkg.src_uri.iter_flatten())
        assert u.uri == "https://a.com/b.tar.gz"
        assert u.rename is None

        pkg = ebuild_repo.create_pkg("cat/pkg-1", src_uri="https://a.com/z -> z.tar.xz")
        assert str(pkg.src_uri) == "https://a.com/z -> z.tar.xz"
        u = next(pkg.src_uri.iter_flatten())
        assert u.uri == "https://a.com/z"
        assert u.rename == "z.tar.xz"

        pkg = ebuild_repo.create_pkg(
            "cat/pkg-1",
            src_uri="u1? ( https://a.com/b.tar.gz ) u2? ( https://a.com/z -> z.tar.xz )",
        )
        assert (
            str(pkg.src_uri) == "u1? ( https://a.com/b.tar.gz ) u2? ( https://a.com/z -> z.tar.xz )"
        )
        assert list(map(str, pkg.src_uri.iter_flatten())) == [
            "https://a.com/b.tar.gz",
            "https://a.com/z -> z.tar.xz",
        ]

    def test_defined_phases(self, ebuild_repo):
        # none
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert not pkg.defined_phases

        # single
        data = "src_configure() { :; }"
        pkg = ebuild_repo.create_pkg("cat/pkg-1", data=data)
        assert pkg.defined_phases == {"configure"}

        # multiple
        data = textwrap.dedent(
            """
            src_prepare() { :; }
            src_configure() { :; }
            src_compile() { :; }
        """
        )
        pkg = ebuild_repo.create_pkg("cat/pkg-1", data=data)
        assert pkg.defined_phases == {"prepare", "configure", "compile"}

    def test_homepage(self, ebuild_repo):
        # none
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert not pkg.homepage

        # single
        pkg = ebuild_repo.create_pkg("cat/pkg-1", homepage="https://a.com")
        assert len(pkg.homepage) == 1

        # multiple
        pkg = ebuild_repo.create_pkg("cat/pkg-1", homepage="https://a.com https://b.com")
        assert pkg.homepage == {"https://a.com", "https://b.com"}

    def test_keywords(self, ebuild_repo):
        # empty
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert not pkg.keywords

        # multiple
        pkg = ebuild_repo.create_pkg("cat/pkg-1", keywords="amd64 ~arm64")
        assert pkg.keywords == {"amd64", "~arm64"}

    def test_iuse(self, ebuild_repo):
        # empty
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert not pkg.iuse

        # multiple
        pkg = ebuild_repo.create_pkg("cat/pkg-1", iuse="a b c")
        assert pkg.iuse == {"a", "b", "c"}

    def test_inherits(self, ebuild_repo):
        # empty
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert not pkg.inherit
        assert not pkg.inherited

    def test_long_description(self, ebuild_repo):
        # none
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert pkg.long_description is None

        # invalid
        path = ebuild_repo.create_ebuild("cat/a-1")
        with open(path.parent / "metadata.xml", "w") as f:
            f.write(
                textwrap.dedent(
                    """
                <pkgmetadata>
                    <longdescription>
                        long description
                    </longdescription>
                </pkg>
            """
                )
            )
        pkg = next(ebuild_repo.iter_restrict("cat/a-1"))
        assert pkg.long_description is None

        # empty
        path = ebuild_repo.create_ebuild("cat/b-1")
        with open(path.parent / "metadata.xml", "w") as f:
            f.write(
                textwrap.dedent(
                    """
                <pkgmetadata>
                    <longdescription>
                    </longdescription>
                </pkgmetadata>
            """
                )
            )
        pkg = next(ebuild_repo.iter_restrict("cat/b-1"))
        assert pkg.long_description == ""

        # exists
        path = ebuild_repo.create_ebuild("cat/c-1")
        with open(path.parent / "metadata.xml", "w") as f:
            f.write(
                textwrap.dedent(
                    """
                <pkgmetadata>
                    <longdescription>
                        long description
                    </longdescription>
                </pkgmetadata>
            """
                )
            )
        pkg = next(ebuild_repo.iter_restrict("cat/c-1"))
        assert pkg.long_description == "long description"

    def test_maintainers(self, ebuild_repo):
        # none
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert not pkg.maintainers

        # invalid
        path = ebuild_repo.create_ebuild("cat/a-1")
        with open(path.parent / "metadata.xml", "w") as f:
            f.write(
                textwrap.dedent(
                    """
                <pkgmetadata>
                </pkg>
            """
                )
            )
        pkg = next(ebuild_repo.iter_restrict("cat/a-1"))
        assert not pkg.maintainers

        # multiple
        path = ebuild_repo.create_ebuild("cat/b-1")
        with open(path.parent / "metadata.xml", "w") as f:
            f.write(
                textwrap.dedent(
                    """
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
            """
                )
            )
        pkg = next(ebuild_repo.iter_restrict("cat/b-1"))
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

    def test_upstreams(self, ebuild_repo):
        # none
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert not pkg.upstreams

        # invalid
        path = ebuild_repo.create_ebuild("cat/a-1")
        with open(path.parent / "metadata.xml", "w") as f:
            f.write(
                textwrap.dedent(
                    """
                <pkgmetadata>
                </pkg>
            """
                )
            )
        pkg = next(ebuild_repo.iter_restrict("cat/a-1"))
        assert not pkg.upstreams

        # multiple
        path = ebuild_repo.create_ebuild("cat/b-1")
        with open(path.parent / "metadata.xml", "w") as f:
            f.write(
                textwrap.dedent(
                    """
                <pkgmetadata>
                    <upstream>
                        <remote-id type="github">pkgcraft/pkgcraft</remote-id>
                        <remote-id type="pypi">pkgcraft</remote-id>
                    </upstream>
                </pkgmetadata>
            """
                )
            )
        pkg = next(ebuild_repo.iter_restrict("cat/b-1"))
        assert len(pkg.upstreams) == 2
        assert str(pkg.upstreams[0]) == "github: pkgcraft/pkgcraft"
        assert repr(pkg.upstreams[0]) == "<Upstream 'github: pkgcraft/pkgcraft'>"
        assert str(pkg.upstreams[1]) == "pypi: pkgcraft"
        assert repr(pkg.upstreams[1]) == "<Upstream 'pypi: pkgcraft'>"

        # verify hashing support
        assert len(set(pkg.upstreams)) == 2
