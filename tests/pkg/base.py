import pytest

from pkgcraft.dep import Cpv, Version
from pkgcraft.eapi import EAPI_LATEST_OFFICIAL
from pkgcraft.restrict import Restrict

from ..misc import OperatorIterMap, OperatorMap


class BasePkgTests:
    def test_cpv_base(self, repo):
        pkg = repo.create_pkg("cat/pkg-1-r2")
        assert pkg.p == "pkg-1"
        assert pkg.pf == "pkg-1-r2"
        assert pkg.pr == "r2"
        assert pkg.pv == "1"
        assert pkg.pvr == "1-r2"
        assert pkg.cpn == "cat/pkg"
        assert pkg.cpv == Cpv("cat/pkg-1-r2")

    def test_eapi_base(self, pkg):
        assert pkg.eapi is EAPI_LATEST_OFFICIAL

    def test_repo(self, pkg, repo):
        assert pkg.repo == repo
        # repo attribute allows recursion
        assert pkg == next(iter(pkg.repo))

    def test_version_base(self, pkg):
        assert pkg.version == Version("1")

    def test_matches_base(self, pkg):
        pkg_restrict = Restrict(pkg)
        cpv_restrict = Restrict(pkg.cpv)
        assert pkg.matches(pkg_restrict)
        assert pkg.matches(cpv_restrict)

    def test_cmp_base(self, repo, testdata_toml):
        # version-based comparisons
        for s in testdata_toml["version.toml"]["compares"]:
            a, op, b = s.split()
            pkg1 = repo.create_pkg(f"cat/pkg-{a}")
            pkg2 = repo.create_pkg(f"cat/pkg-{b}")
            for op_func in OperatorIterMap[op]:
                assert op_func(pkg1, pkg2), f"failed comparison: {s}"

        # category and package take priority over version comparisons
        pkg1 = repo.create_pkg("cat/pkg-1")
        pkg2 = repo.create_pkg("Cat/pkg-2")
        assert pkg2 < pkg1
        pkg1 = repo.create_pkg("cat/pkg-1")
        pkg2 = repo.create_pkg("cat/Pkg-2")
        assert pkg2 < pkg1

        # verify incompatible type comparisons
        obj = repo.create_pkg("cat/pkg-1")
        for op, op_func in OperatorMap.items():
            if op == "==":
                assert not op_func(obj, None)
            elif op == "!=":
                assert op_func(obj, None)
            else:
                with pytest.raises(TypeError):
                    op_func(obj, None)

    def test_str_base(self, pkg):
        assert str(pkg) == "cat/pkg-1::fake"

    def test_repr_base(self, pkg):
        cls = pkg.__class__.__name__
        assert repr(pkg).startswith(f"<{cls} 'cat/pkg-1::fake' at 0x")

    def test_hash_base(self, repo, testdata_toml):
        for d in testdata_toml["version.toml"]["hashing"]:
            pkgs = {repo.create_pkg(f"cat/pkg-{x}") for x in d["versions"]}
            length = 1 if d["equal"] else len(d["versions"])
            assert len(pkgs) == length
