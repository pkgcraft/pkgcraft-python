class TestDepSet:
    def test_attrs(self, ebuild_repo):
        pkg = ebuild_repo.create_pkg("cat/pkg-1", depend="a/b")
        assert str(pkg.depend) == "a/b"
        assert repr(pkg.depend).startswith("<Dependencies 'a/b' at 0x")

    def test_eq_and_hash(self, ebuild_repo):
        # ordering that doesn't matter for equivalence and hashing
        for dep, rdep in (
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
        for dep, rdep in (("|| ( a/b c/d )", "|| ( c/d a/b )"),):
            pkg = ebuild_repo.create_pkg("cat/pkg-1", depend=dep, rdepend=rdep)
            assert pkg.depend != pkg.rdepend, f"{dep} != {rdep}"
            assert len({pkg.depend, pkg.rdepend}) == 2

        # verify incompatible type comparisons
        pkg = ebuild_repo.create_pkg("cat/pkg-1", depend="a/b")
        assert not pkg.depend == None
        assert pkg.depend != None

    def test_ownership(self, ebuild_repo):
        """Verify owned objects are used and persist when parents are dropped."""
        pkg = ebuild_repo.create_pkg("cat/pkg-1", depend="a/b")
        deps = iter(pkg.depend)
        depend = pkg.depend
        del pkg
        assert str(next(deps)) == "a/b"
        assert str(depend) == "a/b"
