import textwrap

import pytest

from pkgcraft.dep import Dep
from pkgcraft.eapi import EAPI_LATEST, EAPIS
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
        assert pkg.path.read_text() == pkg.ebuild

        # missing file causes error
        pkg.path.unlink()
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

    def test_dependencies(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1")

        # invalid keys
        with pytest.raises(PkgcraftError):
            pkg.dependencies("invalid")

        # empty deps
        deps = pkg.dependencies()
        assert str(deps) == ""
        assert list(iter(deps)) == list(iter(iter(deps)))
        assert not list(deps.iter_flatten())
        assert not list(deps.iter_recursive())

        # single type
        pkg = ebuild_repo.create_pkg("cat/pkg-1", depend="cat/pkg")
        deps = pkg.dependencies()
        assert str(deps) == "cat/pkg"
        assert list(iter(deps)) == list(iter(iter(deps)))
        assert list(deps.iter_flatten()) == [Dep("cat/pkg")]
        assert list(map(str, deps.iter_recursive())) == ["cat/pkg"]

        # multiple types -- output in lexical attr name order
        pkg = ebuild_repo.create_pkg("cat/pkg-1", depend="u? ( cat/pkg )", bdepend="a/b")
        deps = pkg.dependencies()
        assert str(deps) == "a/b u? ( cat/pkg )"
        assert list(iter(deps)) == list(iter(iter(deps)))
        assert list(deps.iter_flatten()) == [Dep("a/b"), Dep("cat/pkg")]
        assert list(map(str, deps.iter_recursive())) == ["a/b", "u? ( cat/pkg )", "cat/pkg"]

        # filter by type
        deps = pkg.dependencies("bdepend")
        assert str(deps) == "a/b"
        assert list(iter(deps)) == list(iter(iter(deps)))
        assert list(deps.iter_flatten()) == [Dep("a/b")]
        assert list(map(str, deps.iter_recursive())) == ["a/b"]

        # multiple types with overlapping deps
        pkg = ebuild_repo.create_pkg("cat/pkg-1", depend="u? ( cat/pkg )", bdepend="u? ( cat/pkg )")
        deps = pkg.dependencies()
        assert deps == pkg.dependencies("depend", "bdepend")
        assert str(deps) == "u? ( cat/pkg )"
        assert list(iter(deps)) == list(iter(iter(deps)))
        assert list(deps.iter_flatten()) == [Dep("cat/pkg")]
        assert list(map(str, deps.iter_recursive())) == ["u? ( cat/pkg )", "cat/pkg"]

        # uppercase and lowercase keys work the same
        assert pkg.dependencies("bdepend") == pkg.dependencies("BDEPEND")

    def test_dep_attrs(self, ebuild_repo):
        for attr in map(lambda x: x.lower(), EAPI_LATEST.dep_keys):
            # undefined
            pkg = ebuild_repo.create_pkg("cat/pkg-1")
            assert getattr(pkg, attr) is None

            # explicitly defined empty
            pkg = ebuild_repo.create_pkg("cat/pkg-1", **{attr: ""})
            assert getattr(pkg, attr) is None

            pkg = ebuild_repo.create_pkg("cat/pkg-1", **{attr: "cat/pkg"})
            val = getattr(pkg, attr)
            assert str(val) == "cat/pkg"
            assert list(val.iter_flatten()) == [Dep("cat/pkg")]
            assert list(map(str, val.iter_recursive())) == ["cat/pkg"]
            assert list(map(str, val)) == ["cat/pkg"]

            pkg = ebuild_repo.create_pkg("cat/pkg-1", **{attr: "u? ( cat/pkg ) || ( a/b c/d )"})
            val = getattr(pkg, attr)
            assert str(val) == "u? ( cat/pkg ) || ( a/b c/d )"
            assert list(val.iter_flatten()) == [Dep("cat/pkg"), Dep("a/b"), Dep("c/d")]
            assert list(map(str, val.iter_recursive())) == [
                "u? ( cat/pkg )",
                "cat/pkg",
                "|| ( a/b c/d )",
                "a/b",
                "c/d",
            ]
            dep_restricts = list(val)
            assert list(map(str, dep_restricts)) == ["u? ( cat/pkg )", "|| ( a/b c/d )"]
            dep_restrict = dep_restricts[1]
            assert list(dep_restrict.iter_flatten()) == [Dep("a/b"), Dep("c/d")]
            assert list(map(str, dep_restrict.iter_recursive())) == ["|| ( a/b c/d )", "a/b", "c/d"]

            pkg = ebuild_repo.create_pkg("cat/pkg-1", **{attr: "u? ( a/b ) c/d"})
            val = getattr(pkg, attr)
            assert str(val) == "u? ( a/b ) c/d"
            assert list(val.iter_flatten()) == [Dep("a/b"), Dep("c/d")]
            assert list(map(str, val.iter_recursive())) == ["u? ( a/b )", "a/b", "c/d"]
            dep_restricts = list(val)
            assert list(map(str, dep_restricts)) == ["u? ( a/b )", "c/d"]
            dep_restrict = dep_restricts[1]
            assert list(dep_restrict.iter_flatten()) == [Dep("c/d")]
            assert list(map(str, dep_restrict.iter_recursive())) == ["c/d"]

    def test_ownership(self, ebuild_repo):
        """Verify owned objects are used and persist when parents are dropped."""
        pkg = ebuild_repo.create_pkg("cat/pkg-1", depend="a/b")
        deps = iter(pkg.depend)
        depend = pkg.depend
        del pkg
        assert str(next(deps)) == "a/b"
        assert str(depend) == "a/b"

    def test_license(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert pkg.license is None

        pkg = ebuild_repo.create_pkg("cat/pkg-1", license="BSD")
        assert str(pkg.license) == "BSD"
        assert list(pkg.license.iter_flatten()) == ["BSD"]
        assert list(map(str, pkg.license.iter_recursive())) == ["BSD"]

        pkg = ebuild_repo.create_pkg("cat/pkg-1", license="u? ( BSD )")
        assert str(pkg.license) == "u? ( BSD )"
        assert list(pkg.license.iter_flatten()) == ["BSD"]
        assert list(map(str, pkg.license.iter_recursive())) == ["u? ( BSD )", "BSD"]

    def test_properties(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert pkg.properties is None

        pkg = ebuild_repo.create_pkg("cat/pkg-1", properties="live")
        assert str(pkg.properties) == "live"
        assert list(pkg.properties.iter_flatten()) == ["live"]
        assert list(map(str, pkg.properties.iter_recursive())) == ["live"]

        pkg = ebuild_repo.create_pkg("cat/pkg-1", properties="u? ( live )")
        assert str(pkg.properties) == "u? ( live )"
        assert list(pkg.properties.iter_flatten()) == ["live"]
        assert list(map(str, pkg.properties.iter_recursive())) == ["u? ( live )", "live"]

    def test_required_use(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert pkg.required_use is None

        pkg = ebuild_repo.create_pkg("cat/pkg-1", required_use="use")
        assert str(pkg.required_use) == "use"
        assert list(pkg.required_use.iter_flatten()) == ["use"]
        assert list(map(str, pkg.required_use.iter_recursive())) == ["use"]

        pkg = ebuild_repo.create_pkg("cat/pkg-1", required_use="u1? ( u2 )")
        assert str(pkg.required_use) == "u1? ( u2 )"
        assert list(pkg.required_use.iter_flatten()) == ["u2"]
        assert list(map(str, pkg.required_use.iter_recursive())) == ["u1? ( u2 )", "u2"]

    def test_restrict(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert pkg.restrict is None

        pkg = ebuild_repo.create_pkg("cat/pkg-1", restrict="fetch")
        assert str(pkg.restrict) == "fetch"
        assert list(pkg.restrict.iter_flatten()) == ["fetch"]
        assert list(map(str, pkg.restrict.iter_recursive())) == ["fetch"]

        pkg = ebuild_repo.create_pkg("cat/pkg-1", restrict="u? ( fetch )")
        assert str(pkg.restrict) == "u? ( fetch )"
        assert list(pkg.restrict.iter_flatten()) == ["fetch"]
        assert list(map(str, pkg.restrict.iter_recursive())) == ["u? ( fetch )", "fetch"]

    def test_src_uri(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert pkg.src_uri is None

        pkg = ebuild_repo.create_pkg("cat/pkg-1", src_uri="https://a.com/b.tar.gz")
        assert str(pkg.src_uri) == "https://a.com/b.tar.gz"
        u = next(pkg.src_uri.iter_flatten())
        assert u.uri == "https://a.com/b.tar.gz"
        assert u.filename == "b.tar.gz"
        assert list(map(str, pkg.src_uri.iter_recursive())) == ["https://a.com/b.tar.gz"]

        pkg = ebuild_repo.create_pkg("cat/pkg-1", src_uri="https://a.com/z -> z.tar.xz")
        assert str(pkg.src_uri) == "https://a.com/z -> z.tar.xz"
        u = next(pkg.src_uri.iter_flatten())
        assert u.uri == "https://a.com/z"
        assert u.filename == "z.tar.xz"
        assert list(map(str, pkg.src_uri.iter_recursive())) == ["https://a.com/z -> z.tar.xz"]

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
        assert list(map(str, pkg.src_uri.iter_recursive())) == [
            "u1? ( https://a.com/b.tar.gz )",
            "https://a.com/b.tar.gz",
            "u2? ( https://a.com/z -> z.tar.xz )",
            "https://a.com/z -> z.tar.xz",
        ]

    def test_defined_phases(self, ebuild_repo):
        # none
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert pkg.defined_phases == []

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
        assert pkg.homepage == []

        # single
        pkg = ebuild_repo.create_pkg("cat/pkg-1", homepage="https://a.com")
        assert len(pkg.homepage) == 1

        # multiple
        pkg = ebuild_repo.create_pkg("cat/pkg-1", homepage="https://a.com https://b.com")
        assert pkg.homepage == {"https://a.com", "https://b.com"}

    def test_keywords(self, ebuild_repo):
        # empty
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert pkg.keywords == []

        # multiple
        pkg = ebuild_repo.create_pkg("cat/pkg-1", keywords="amd64 ~arm64")
        assert pkg.keywords == {"amd64", "~arm64"}

    def test_iuse(self, ebuild_repo):
        # empty
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert pkg.iuse == []

        # multiple
        pkg = ebuild_repo.create_pkg("cat/pkg-1", iuse="a b c")
        assert pkg.iuse == {"a", "b", "c"}

    def test_inherits(self, ebuild_repo, testdata_config):
        # none
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert pkg.inherit == []
        assert pkg.inherited == []

        repo = testdata_config.repos["eclasses"]

        # nested inherits
        pkg = repo["pkg-tests/inherits-1"]
        assert pkg.inherit == {"leaf"}
        assert pkg.inherited == {"leaf", "base"}

        # non-nested inherits
        pkg = repo["pkg-tests/inherits-2"]
        assert pkg.inherit == {"base"}
        assert pkg.inherited == {"base"}

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
        pkg = next(ebuild_repo.iter("cat/a-1"))
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
        pkg = next(ebuild_repo.iter("cat/b-1"))
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
        pkg = next(ebuild_repo.iter("cat/c-1"))
        assert pkg.long_description == "long description"

    def test_maintainers(self, ebuild_repo):
        # none
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert pkg.maintainers == []

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
        pkg = next(ebuild_repo.iter("cat/a-1"))
        assert pkg.maintainers == []

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
        pkg = next(ebuild_repo.iter("cat/b-1"))
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

    def test_upstream(self, ebuild_repo):
        # none
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert pkg.upstream is None

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
        pkg = next(ebuild_repo.iter("cat/a-1"))
        assert pkg.upstream is None

        # multiple remote-id
        path = ebuild_repo.create_ebuild("cat/b-1")
        with open(path.parent / "metadata.xml", "w") as f:
            f.write(
                textwrap.dedent(
                    """
                <pkgmetadata>
                    <upstream>
                        <remote-id type="github">pkgcraft/pkgcraft</remote-id>
                        <remote-id type="pypi">pkgcraft</remote-id>
                        <bugs-to>https://github.com/pkgcraft/pkgcraft/issues</bugs-to>
                        <changelog> </changelog>
                        <doc> https://github.com/pkgcraft/pkgcraft  </doc>
                        <maintainer status="active">
                            <email>an@email.address</email>
                            <name>A Person</name>
                        </maintainer>
                    </upstream>
                </pkgmetadata>
            """
                )
            )
        pkg = next(ebuild_repo.iter("cat/b-1"))
        u = pkg.upstream
        assert list(map(str, u.maintainers)) == ["A Person <an@email.address> (active)"]
        assert list(map(repr, u.maintainers)) == [
            "<UpstreamMaintainer 'A Person <an@email.address> (active)'>"
        ]
        assert u.bugs_to == "https://github.com/pkgcraft/pkgcraft/issues"
        assert u.changelog is None
        assert u.doc == "https://github.com/pkgcraft/pkgcraft"
        assert len(u.remote_ids) == 2
        assert list(map(str, u.remote_ids)) == ["github: pkgcraft/pkgcraft", "pypi: pkgcraft"]
        assert list(map(repr, u.remote_ids)) == [
            "<RemoteId 'github: pkgcraft/pkgcraft'>",
            "<RemoteId 'pypi: pkgcraft'>",
        ]
