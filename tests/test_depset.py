from .misc import OperatorMap


class TestDepSet:
    def test_attrs(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1", depend="a/b")
        assert str(pkg.depend) == "a/b"
        assert repr(pkg.depend).startswith("<DepSet 'a/b' at 0x")

    def test_eq_and_hash(self, ebuild_repo):
        # ordering that doesn't matter for equivalence and hashing
        for (dep, rdep) in (
            # same deps
            ("a/dep", "a/dep"),
            ("use? ( a/dep )", "use? ( a/dep )"),
            ("use? ( a/dep || ( a/b c/d ) )", "use? ( a/dep || ( a/b c/d ) )"),
            # different order, but equivalent
            ("a/b c/d", "c/d a/b"),
            ("use? ( a/b c/d )", "use? ( c/d a/b )"),
        ):
            pkg = ebuild_repo.create_pkg("cat/pkg-1", depend=dep, rdepend=rdep)
            assert pkg.depend == pkg.rdepend, f"{dep} != {rdep}"
            assert len({pkg.depend, pkg.rdepend}) == 1

        # ordering that matters for equivalence and hashing
        for (dep, rdep) in (("|| ( a/b c/d )", "|| ( c/d a/b )"),):
            pkg = ebuild_repo.create_pkg("cat/pkg-1", depend=dep, rdepend=rdep)
            assert pkg.depend != pkg.rdepend, f"{dep} != {rdep}"
            assert len({pkg.depend, pkg.rdepend}) == 2

    def test_ownership(self, ebuild_repo):
        """Verify owned objects are used and persist when parents are dropped."""
        pkg = ebuild_repo.create_pkg("cat/pkg-1", depend="a/b")
        deps = iter(pkg.depend)
        depend = pkg.depend
        del pkg
        assert str(next(deps)) == "a/b"
        assert str(depend) == "a/b"


class TestDepRestrict:
    def test_attrs(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1", depend="a/b")
        d = next(iter(pkg.depend))
        assert str(d) == "a/b"
        assert repr(d).startswith("<DepRestrict 'a/b' at 0x")

    def test_cmp(self, ebuild_repo):
        for (dep, op, rdep) in (
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
            assert op_func(d1, d2), f"failed {r1_args} {op} {r2_args}"

    def test_eq_and_hash(self, ebuild_repo):
        # ordering that doesn't matter for equivalence and hashing
        for (dep, rdep) in (
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
        for (dep, rdep) in (("|| ( a/b c/d )", "|| ( c/d a/b )"),):
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
