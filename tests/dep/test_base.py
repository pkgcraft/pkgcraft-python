import pytest

from ..misc import OperatorMap


class TestDep:
    def test_attrs(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1", depend="a/b")
        d = next(iter(pkg.depend))
        assert str(d) == "a/b"
        assert repr(d).startswith("<Enabled 'a/b' at 0x")

    def test_cmp(self, ebuild_repo):
        for dep, op, rdep in (
            ("a/b", "<", "b/a"),
            ("a/b", "<=", "b/a"),
            ("b/a", "<=", "b/a"),
            ("b/a", "==", "b/a"),
            ("b/a", "!=", "a/b"),
            ("b/a", ">=", "a/b"),
            ("b/a", ">", "a/b"),
        ):
            op_func = OperatorMap[op]
            pkg = ebuild_repo.create_pkg("cat/pkg-1", depend=dep, rdepend=rdep)
            d1, d2 = next(iter(pkg.depend)), next(iter(pkg.rdepend))
            assert op_func(d1, d2), f"failed {dep} {op} {rdep}"

        # verify incompatible type comparisons
        pkg = ebuild_repo.create_pkg("cat/pkg-1", depend="a/b")
        obj = next(iter(pkg.depend))
        for op, op_func in OperatorMap.items():
            if op == "==":
                assert not op_func(obj, None)
            elif op == "!=":
                assert op_func(obj, None)
            else:
                with pytest.raises(TypeError):
                    op_func(obj, None)

    def test_eq_and_hash(self, ebuild_repo):
        # ordering that doesn't matter for equivalence and hashing
        for dep, rdep in (
            # same deps
            ("a/dep", "a/dep"),
            ("use? ( a/dep )", "use? ( a/dep )"),
            ("use? ( a/dep || ( a/b c/d ) )", "use? ( a/dep || ( a/b c/d ) )"),
            # different order, but equivalent
            ("use? ( a/b c/d )", "use? ( c/d a/b )"),
        ):
            pkg = ebuild_repo.create_pkg("cat/pkg-1", depend=dep, rdepend=rdep)
            d1, d2 = next(iter(pkg.depend)), next(iter(pkg.rdepend))
            assert d1 == d2
            assert len({d1, d2}) == 1

        # ordering that matters for equivalence and hashing
        for dep, rdep in (("|| ( a/b c/d )", "|| ( c/d a/b )"),):
            pkg = ebuild_repo.create_pkg("cat/pkg-1", depend=dep, rdepend=rdep)
            d1, d2 = next(iter(pkg.depend)), next(iter(pkg.rdepend))
            assert d1 != d2
            assert len({d1, d2}) == 2

    def test_ownership(self, ebuild_repo):
        """Verify owned objects are used and persist when parents are dropped."""
        pkg = ebuild_repo.create_pkg("cat/pkg-1", depend="a/b")
        deps = iter(pkg.depend)
        dep = next(iter(pkg.depend))
        del pkg
        assert str(next(deps)) == "a/b"
        assert str(dep) == "a/b"
