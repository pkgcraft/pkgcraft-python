from pkgcraft.dep import Dependencies

class TestDepSet:
    def test_attrs(self):
        dep = Dependencies("a/b")
        assert str(dep) == "a/b"
        assert repr(dep).startswith("<Dependencies 'a/b' at 0x")

    def test_eq_and_hash(self):
        # ordering that doesn't matter for equivalence and hashing
        for dep_s, rdep_s in (
            # same deps
            ("a/dep", "a/dep"),
            ("use? ( a/dep )", "use? ( a/dep )"),
            ("use? ( a/dep || ( a/b c/d ) )", "use? ( a/dep || ( a/b c/d ) )"),
            # different order, but equivalent
            ("a/b c/d", "c/d a/b"),
            ("use? ( a/b c/d )", "use? ( c/d a/b )"),
        ):
            dep = Dependencies(dep_s)
            rdep = Dependencies(rdep_s)
            assert dep == rdep, f"{dep} != {rdep}"
            assert len({dep, rdep}) == 1

        # ordering that matters for equivalence and hashing
        for dep_s, rdep_s in (("|| ( a/b c/d )", "|| ( c/d a/b )"),):
            dep = Dependencies(dep_s)
            rdep = Dependencies(rdep_s)
            assert dep != rdep, f"{dep} != {rdep}"
            assert len({dep, rdep}) == 2

        # verify incompatible type comparisons
        dep = Dependencies("a/b")
        assert not dep == None
        assert dep != None
