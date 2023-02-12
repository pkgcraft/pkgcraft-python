import pytest

from pkgcraft.dep import Cpv, Version
from pkgcraft.eapi import EAPI_LATEST
from pkgcraft.restrict import Restrict

from ..misc import OperatorMap


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
        assert pkg.eapi is EAPI_LATEST

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

    def test_cmp_base(self, repo):
        pkg1 = repo.create_pkg("cat/pkg-1")
        pkg2 = repo.create_pkg("cat/pkg-2")
        assert pkg1 == pkg1
        assert pkg2 == pkg2
        assert pkg1 < pkg2
        assert pkg1 <= pkg2
        assert pkg2 <= pkg2
        assert pkg1 != pkg2
        assert pkg2 >= pkg2
        assert pkg2 >= pkg1
        assert pkg2 > pkg1

        # verify incompatible type comparisons
        obj = pkg1
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

    def test_hash_base(self, repo):
        pkg1 = repo.create_pkg("cat/pkg-1")
        pkg2 = repo.create_pkg("cat/pkg-2")
        assert len({pkg1, pkg1}) == 1
        assert len({pkg1, pkg2}) == 2
