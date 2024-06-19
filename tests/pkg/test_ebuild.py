import textwrap
from operator import iand, ior, isub, ixor

import pytest

from pkgcraft.dep import Dep
from pkgcraft.eapi import EAPI_LATEST_OFFICIAL, EAPIS_OFFICIAL
from pkgcraft.error import PkgcraftError
from pkgcraft.pkg.ebuild import Keyword

from ..misc import TEST_DATA
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
        EAPI_PREV_OFFICIAL = list(EAPIS_OFFICIAL.values())[-2]
        pkg = ebuild_repo.create_pkg("cat/pkg-1", eapi=EAPI_PREV_OFFICIAL)
        assert pkg.eapi is EAPI_PREV_OFFICIAL
        pkg = ebuild_repo.create_pkg("cat/pkg-1", eapi=EAPI_LATEST_OFFICIAL)
        assert pkg.eapi is EAPI_LATEST_OFFICIAL

    def test_intersects(self, make_ebuild_repo):
        repo = make_ebuild_repo(id="test")
        pkg = repo.create_pkg("cat/pkg-1", slot="0/1")
        assert pkg.intersects(Dep("cat/pkg"))
        assert pkg.intersects(Dep("cat/pkg:0"))
        assert not pkg.intersects(Dep("cat/pkg:1"))
        assert pkg.intersects(Dep("cat/pkg:0/1"))
        assert not pkg.intersects(Dep("cat/pkg:0/2"))
        assert pkg.intersects(Dep("cat/pkg::test"))
        assert not pkg.intersects(Dep("cat/pkg::repo"))

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

    def test_deprecated(self):
        pkg = TEST_DATA.repos["metadata"]["deprecated/deprecated-0"]
        assert pkg.deprecated
        pkg = TEST_DATA.repos["metadata"]["deprecated/deprecated-1"]
        assert not pkg.deprecated

    def test_live(self):
        pkg = TEST_DATA.repos["qa-primary"]["Keywords/KeywordsLive-9999"]
        assert pkg.live
        pkg = TEST_DATA.repos["qa-primary"]["Keywords/KeywordsLive-0"]
        assert not pkg.live

    def test_masked(self):
        pkg = TEST_DATA.repos["metadata"]["masked/masked-0"]
        assert pkg.masked
        pkg = TEST_DATA.repos["metadata"]["masked/masked-1"]
        assert not pkg.masked

    def test_description(self):
        pkg = TEST_DATA.repos["metadata"]["optional/none-8"]
        assert pkg.description == "ebuild with no optional metadata fields"

    def test_slot_and_subslot(self):
        pkg = TEST_DATA.repos["metadata"]["slot/slot-8"]
        assert pkg.slot == "1"
        assert pkg.subslot == "1"

        pkg = TEST_DATA.repos["metadata"]["slot/subslot-8"]
        assert pkg.slot == "1"
        assert pkg.subslot == "2"

    def test_dependencies(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1")

        # invalid keys
        for s in ("invalid", "dep"):
            with pytest.raises(PkgcraftError, match=f"invalid dep key: {s}"):
                pkg.dependencies(s)
            with pytest.raises(PkgcraftError, match=f"invalid dep key: {s}"):
                pkg.dependencies("depend", s)

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
        for attr in map(lambda x: x.lower(), EAPI_LATEST_OFFICIAL.dep_keys):
            # undefined
            pkg = ebuild_repo.create_pkg("cat/pkg-1")
            assert not getattr(pkg, attr)

            # explicitly defined empty
            pkg = ebuild_repo.create_pkg("cat/pkg-1", **{attr: ""})
            assert not getattr(pkg, attr)

            pkg = ebuild_repo.create_pkg("cat/pkg-1", **{attr: "cat/pkg"})
            val = getattr(pkg, attr)
            assert str(val) == "cat/pkg"
            assert list(val.iter_flatten()) == [Dep("cat/pkg")]
            assert list(map(str, val.iter_recursive())) == ["cat/pkg"]
            assert list(map(str, val)) == ["cat/pkg"]

            # modifying operations return new sets
            for op_func in (iand, ior, isub, ixor):
                v = op_func(val, val)
                assert v is not val

            # pkg depset attrs are immutable
            with pytest.raises(TypeError):
                val[0] = "cat/pkg"
            with pytest.raises(TypeError):
                val[:] = ["cat/pkg"]

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
        depend = pkg.depend
        dep = pkg.depend[0]
        del pkg
        assert str(depend) == "a/b"
        assert str(dep) == "a/b"

    def test_license(self):
        # none
        pkg = TEST_DATA.repos["metadata"]["optional/none-8"]
        assert not pkg.license

        # empty
        pkg = TEST_DATA.repos["metadata"]["optional/empty-8"]
        assert not pkg.license

        # single-line
        pkg = TEST_DATA.repos["metadata"]["license/single-8"]
        assert str(pkg.license) == "l1 l2"

        # multi-line
        pkg = TEST_DATA.repos["metadata"]["license/multi-8"]
        assert str(pkg.license) == "l1 u? ( l2 )"

        # inherited and overridden
        pkg = TEST_DATA.repos["metadata"]["license/inherit-8"]
        assert str(pkg.license) == "l1"

        # inherited and appended
        pkg = TEST_DATA.repos["metadata"]["license/append-8"]
        assert str(pkg.license) == "l2 l1"

    def test_properties(self):
        # none
        pkg = TEST_DATA.repos["metadata"]["optional/none-8"]
        assert not pkg.properties

        # empty
        pkg = TEST_DATA.repos["metadata"]["optional/empty-8"]
        assert not pkg.properties

        # single-line
        pkg = TEST_DATA.repos["metadata"]["properties/single-8"]
        assert str(pkg.properties) == "1 2"

        # multi-line
        pkg = TEST_DATA.repos["metadata"]["properties/multi-8"]
        assert str(pkg.properties) == "u? ( 1 2 )"

        # non-incremental inherit (EAPI 7)
        pkg = TEST_DATA.repos["metadata"]["properties/inherit-7"]
        assert str(pkg.properties) == "global ebuild"

        # incremental inherit (EAPI 8)
        pkg = TEST_DATA.repos["metadata"]["properties/inherit-8"]
        assert str(pkg.properties) == "global ebuild eclass a b"

    def test_required_use(self):
        # none
        pkg = TEST_DATA.repos["metadata"]["optional/none-8"]
        assert not pkg.required_use

        # empty
        pkg = TEST_DATA.repos["metadata"]["optional/empty-8"]
        assert not pkg.required_use

        # single-line
        pkg = TEST_DATA.repos["metadata"]["required_use/single-8"]
        assert str(pkg.required_use) == "u1 u2"

        # multi-line
        pkg = TEST_DATA.repos["metadata"]["required_use/multi-8"]
        assert str(pkg.required_use) == "^^ ( u1 u2 )"

        # incremental inherit
        pkg = TEST_DATA.repos["metadata"]["required_use/inherit-8"]
        assert str(pkg.required_use) == "global ebuild eclass a b"

    def test_restrict(self):
        # none
        pkg = TEST_DATA.repos["metadata"]["optional/none-8"]
        assert not pkg.restrict

        # empty
        pkg = TEST_DATA.repos["metadata"]["optional/empty-8"]
        assert not pkg.restrict

        # single-line
        pkg = TEST_DATA.repos["metadata"]["restrict/single-8"]
        assert str(pkg.restrict) == "1 2"

        # multi-line
        pkg = TEST_DATA.repos["metadata"]["restrict/multi-8"]
        assert str(pkg.restrict) == "u? ( 1 2 )"

        # non-incremental inherit (EAPI 7)
        pkg = TEST_DATA.repos["metadata"]["restrict/inherit-7"]
        assert str(pkg.restrict) == "global ebuild"

        # incremental inherit (EAPI 8)
        pkg = TEST_DATA.repos["metadata"]["restrict/inherit-8"]
        assert str(pkg.restrict) == "global ebuild eclass a b"

    def test_src_uri(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1")
        assert not pkg.src_uri

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

    def test_defined_phases(self):
        # none
        pkg = TEST_DATA.repos["metadata"]["optional/none-8"]
        assert pkg.defined_phases == []

        # ebuild-defined
        pkg = TEST_DATA.repos["metadata"]["phases/direct-8"]
        assert pkg.defined_phases == ["src_compile", "src_install", "src_prepare"]

        # eclass-defined
        pkg = TEST_DATA.repos["metadata"]["phases/indirect-8"]
        assert pkg.defined_phases == ["src_install", "src_prepare", "src_test"]

    def test_homepage(self):
        # none
        pkg = TEST_DATA.repos["metadata"]["optional/none-8"]
        assert pkg.homepage == []

        # empty
        pkg = TEST_DATA.repos["metadata"]["optional/empty-8"]
        assert pkg.homepage == []

        # single-line
        pkg = TEST_DATA.repos["metadata"]["homepage/single-8"]
        assert pkg.homepage == ["https://github.com/pkgcraft/1", "https://github.com/pkgcraft/2"]

        # multi-line
        pkg = TEST_DATA.repos["metadata"]["homepage/multi-8"]
        assert pkg.homepage == ["https://github.com/pkgcraft/1", "https://github.com/pkgcraft/2"]

        # inherited and overridden
        pkg = TEST_DATA.repos["metadata"]["homepage/inherit-8"]
        assert pkg.homepage == ["https://github.com/pkgcraft/1"]

        # inherited and appended
        pkg = TEST_DATA.repos["metadata"]["homepage/append-8"]
        assert pkg.homepage == ["https://github.com/pkgcraft/a", "https://github.com/pkgcraft/1"]

    def test_keywords(self):
        # none
        pkg = TEST_DATA.repos["metadata"]["optional/none-8"]
        assert pkg.keywords == []

        # empty
        pkg = TEST_DATA.repos["metadata"]["optional/empty-8"]
        assert pkg.keywords == []

        # single line
        pkg = TEST_DATA.repos["metadata"]["keywords/single-8"]
        assert pkg.keywords == [Keyword("amd64"), Keyword("~arm64")]

        # multiple lines
        pkg = TEST_DATA.repos["metadata"]["keywords/multi-8"]
        assert pkg.keywords == [Keyword("~amd64"), Keyword("arm64")]

    def test_iuse(self):
        # none
        pkg = TEST_DATA.repos["metadata"]["optional/none-8"]
        assert pkg.iuse == []

        # empty
        pkg = TEST_DATA.repos["metadata"]["optional/empty-8"]
        assert pkg.iuse == []

        # single-line
        pkg = TEST_DATA.repos["metadata"]["iuse/single-8"]
        assert pkg.iuse == ["a", "+b", "-c"]

        # multi-line
        pkg = TEST_DATA.repos["metadata"]["iuse/multi-8"]
        assert pkg.iuse == ["a", "+b", "-c"]

        # incremental inherit
        pkg = TEST_DATA.repos["metadata"]["iuse/inherit-8"]
        assert pkg.iuse == ["global", "ebuild", "eclass", "a", "b"]

    def test_inherits(self):
        # none
        pkg = TEST_DATA.repos["metadata"]["optional/none-8"]
        assert pkg.inherit == []
        assert pkg.inherited == []

        # direct inherit
        pkg = TEST_DATA.repos["metadata"]["inherit/direct-8"]
        assert pkg.inherit == ["a"]
        assert pkg.inherited == ["a"]

        # indirect inherit
        pkg = TEST_DATA.repos["metadata"]["inherit/indirect-8"]
        assert pkg.inherit == ["b"]
        assert pkg.inherited == ["b", "a"]

    def test_long_description(self):
        # none
        pkg = TEST_DATA.repos["xml"]["pkg/none-8"]
        assert pkg.long_description is None

        # invalid
        pkg = TEST_DATA.repos["xml"]["pkg/bad-8"]
        assert pkg.long_description is None

        # empty
        pkg = TEST_DATA.repos["xml"]["pkg/empty-8"]
        assert pkg.long_description is None

        # single
        pkg = TEST_DATA.repos["xml"]["pkg/single-8"]
        assert pkg.long_description == "A wrapped sentence. Another sentence. New paragraph."

        # multiple
        pkg = TEST_DATA.repos["xml"]["pkg/multiple-8"]
        assert pkg.long_description == "A wrapped sentence. Another sentence. New paragraph."

    def test_maintainers(self, ebuild_repo):
        # none
        pkg = TEST_DATA.repos["xml"]["pkg/none-8"]
        assert pkg.maintainers == []

        # invalid
        pkg = TEST_DATA.repos["xml"]["pkg/bad-8"]
        assert pkg.maintainers == []

        # single
        pkg = TEST_DATA.repos["xml"]["pkg/single-8"]
        assert len(pkg.maintainers) == 1
        assert str(pkg.maintainers[0]) == "A Person <a.person@email.com>"
        assert repr(pkg.maintainers[0]) == "<Maintainer 'a.person@email.com'>"
        assert pkg.maintainers[0].maint_type == "person"

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
        pkg = TEST_DATA.repos["xml"]["pkg/none-8"]
        assert pkg.upstream is None

        # invalid
        pkg = TEST_DATA.repos["xml"]["pkg/bad-8"]
        assert pkg.upstream is None

        # single
        pkg = TEST_DATA.repos["xml"]["pkg/single-8"]
        u = pkg.upstream
        assert len(u.remote_ids) == 1
        assert list(map(str, u.remote_ids)) == ["github: pkgcraft/pkgcraft"]
        assert list(map(repr, u.remote_ids)) == ["<RemoteId 'github: pkgcraft/pkgcraft'>"]

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
