import pytest

from pkgcraft.atom import Atom, Cpv
from pkgcraft.config import Config
from pkgcraft.error import InvalidRestrict
from pkgcraft.repo import RepoSet

from ..misc import OperatorMap


class TestRepoSet:
    def test_attrs(self, make_fake_repo):
        r1 = make_fake_repo()
        r2 = make_fake_repo()
        s = RepoSet(r1, r2)
        assert str(s)
        assert repr(s).startswith("<RepoSet ")

    def test_repos(self, make_fake_repo):
        r1 = make_fake_repo()
        r2 = make_fake_repo()
        s = RepoSet(r1, r2)
        assert s.repos == (r1, r2)

        r1 = make_fake_repo(priority=1)
        r2 = make_fake_repo(priority=2)
        s = RepoSet(r1, r2)
        assert s.repos == (r2, r1)

    def test_pkg_methods(self, make_fake_repo):
        # empty repo set
        s = RepoSet()
        assert not s.categories
        assert not s.packages("cat")
        assert not s.versions("cat", "pkg")

        # single pkg
        r1 = make_fake_repo(["cat/pkg-1"])
        r2 = make_fake_repo()
        s = RepoSet(r1, r2)
        assert s.categories == ("cat",)
        assert s.packages("cat") == ("pkg",)
        assert s.versions("cat", "pkg") == ("1",)

        # multiple new pkg version
        r1 = make_fake_repo(["cat/pkg-1", "cat/pkg-2"])
        r2 = make_fake_repo()
        s = RepoSet(r1, r2)
        assert s.categories == ("cat",)
        assert s.packages("cat") == ("pkg",)
        assert s.versions("cat", "pkg") == ("1", "2")

        # matching pkg in other repo
        r1 = make_fake_repo(["cat/pkg-1", "cat/pkg-2"])
        r2 = make_fake_repo(["cat/pkg-1"])
        s = RepoSet(r1, r2)
        assert s.categories == ("cat",)
        assert s.packages("cat") == ("pkg",)
        assert s.versions("cat", "pkg") == ("1", "2")

        # new pkg in new category in other repo
        r1 = make_fake_repo(["cat/pkg-1", "cat/pkg-2"])
        r2 = make_fake_repo(["cat/pkg-1", "a/b-1"])
        s = RepoSet(r1, r2)
        assert s.categories == ("a", "cat")
        assert s.packages("a") == ("b",)
        assert s.versions("a", "b") == ("1",)

    def test_cmp(self, make_fake_repo):
        for (r1, op, r2) in (
            ({"id": "a"}, "<", {"id": "b"}),
            ({"id": "a", "priority": 2}, "<=", {"id": "b", "priority": 1}),
            ({"id": "a"}, "!=", {"id": "b"}),
            ({"id": "b", "priority": 1}, ">=", {"id": "a", "priority": 2}),
            ({"id": "b"}, ">", {"id": "a"}),
        ):
            config = Config()
            op_func = OperatorMap[op]
            err = f"failed {r1} {op} {r2}"
            s1 = RepoSet(make_fake_repo(config=config, **r1))
            s2 = RepoSet(make_fake_repo(config=config, **r2))
            assert op_func(s1, s2), err

    def test_hash(self, make_fake_repo):
        r1 = make_fake_repo()
        r2 = make_fake_repo()
        r3 = make_fake_repo()

        # equal sets
        s1 = RepoSet(r1, r2)
        s2 = RepoSet(r2, r1)
        assert s2 in {s1}

        # unequal sets
        s3 = RepoSet(r1, r3)
        assert s1 not in {s3}

    def test_contains(self, make_fake_repo):
        r1 = make_fake_repo()
        r2 = make_fake_repo()
        pkg1 = r1.create_pkg("cat/pkg-1")
        pkg2 = r2.create_pkg("cat/pkg-1")
        s = RepoSet(r1, r2)

        # Cpv strings
        assert "cat/pkg-1" in s
        assert "cat/pkg-2" not in s
        # Cpv objects
        assert Cpv("cat/pkg-1") in s
        assert Cpv("cat/pkg-2") not in s
        # Atom strings
        assert "cat/pkg" in s
        assert "cat/pkg2" not in s
        assert "=cat/pkg-1" in s
        assert "=cat/pkg-2" not in s
        # Atom objects
        assert Atom("=cat/pkg-1") in s
        assert Atom("=cat/pkg-2") not in s
        # Pkg objects
        assert pkg1 in s
        assert pkg2 in s
        # Pkg atoms
        assert pkg1.atom in s
        assert pkg2.atom in s
        # Repo objects
        assert r1 in s
        assert r2 in s
        r3 = make_fake_repo()
        assert r3 not in s

        for obj in (object(), None):
            with pytest.raises(TypeError):
                assert obj in s

    def test_bool_and_len(self, make_fake_repo):
        s = RepoSet()
        assert not s
        assert len(s) == 0

        s = RepoSet(make_fake_repo())
        assert not s
        assert len(s) == 0

        repo = make_fake_repo(["cat/pkg-1"])
        s = RepoSet(repo)
        assert s
        assert len(s) == 1

    def test_iter(self, make_fake_repo):
        s = RepoSet()

        # calling next() directly on a repo object fails
        with pytest.raises(TypeError):
            next(s)

        # multiple iter() calls free underlying pointer
        iter(s)
        iter(s)

        # empty set
        assert not list(s)

        # single pkg
        r1 = make_fake_repo(["cat/pkg-1"], id="r1", priority=1)
        r2 = make_fake_repo(id="r2", priority=2)
        s = RepoSet(r1, r2)
        assert list(map(str, s)) == ["cat/pkg-1::r1"]

        # multiple pkgs
        r1 = make_fake_repo(["cat/pkg-1"], id="r1", priority=1)
        r2 = make_fake_repo(["cat/pkg-2"], id="r2", priority=2)
        s = RepoSet(r1, r2)
        assert list(map(str, s)) == ["cat/pkg-2::r2", "cat/pkg-1::r1"]

    def test_iter_restrict(self, make_fake_repo):
        s = RepoSet()

        # non-None argument required
        with pytest.raises(TypeError):
            s.iter_restrict(None)

        # unsupported object type
        with pytest.raises(TypeError):
            list(s.iter_restrict(object()))

        cpv = Cpv("cat/pkg-1")

        # empty repo set -- no matches
        assert not list(s.iter_restrict(cpv))

        r1 = make_fake_repo(["cat/pkg-1"], id="r1")
        r2 = make_fake_repo(["cat/pkg-2"], id="r2")
        r3 = make_fake_repo(["cat/pkg-1"], id="r3", priority=1)
        s = RepoSet(r1, r2, r3)

        # non-empty repo -- no matches
        nonexistent = Cpv("nonexistent/pkg-1")
        assert not list(s.iter_restrict(nonexistent))

        # multiple matches via CPV
        assert list(map(str, s.iter_restrict(cpv))) == ["cat/pkg-1::r3", "cat/pkg-1::r1"]

        # single match via package
        pkg = next(s.iter_restrict(cpv))
        assert list(s.iter_restrict(pkg)) == [pkg]

        # multiple matches via restriction glob
        expected = ["cat/pkg-1::r3", "cat/pkg-1::r1", "cat/pkg-2::r2"]
        assert list(map(str, s.iter_restrict("cat/*"))) == expected

        # invalid restriction string
        with pytest.raises(InvalidRestrict):
            list(s.iter_restrict("-"))

    def test_set_ops(self, make_fake_repo):
        r1 = make_fake_repo(priority=1)
        r2 = make_fake_repo(priority=2)
        r3 = make_fake_repo(priority=3)

        # &= operator
        s = RepoSet(r1, r2, r3)
        s &= RepoSet(r1, r2)
        assert s.repos == (r2, r1)
        s &= r1
        assert s.repos == (r1,)
        s &= r3
        assert s.repos == ()

        # |= operator
        s = RepoSet()
        s |= RepoSet(r1, r2)
        assert s.repos == (r2, r1)
        s |= r3
        assert s.repos == (r3, r2, r1)

        # ^= operator
        s = RepoSet(r1, r2, r3)
        s ^= RepoSet(r1, r2)
        assert s.repos == (r3,)
        s ^= r3
        assert s.repos == ()

        # -= operator
        s = RepoSet(r1, r2, r3)
        s -= RepoSet(r1, r2)
        assert s.repos == (r3,)
        s -= r3
        assert s.repos == ()

        # & operator
        s = RepoSet(r1, r2, r3)
        assert (s & RepoSet(r1, r2)).repos == (r2, r1)
        assert (s & r3).repos == (r3,)
        assert (r3 & s).repos == (r3,)
        for (a, b) in [(None, s), ("s", s)]:
            for (x, y) in [(a, b), (b, a)]:
                with pytest.raises(TypeError):
                    x & y

        # | operator
        s = RepoSet(r1)
        assert (s | RepoSet(r2, r3)).repos == (r3, r2, r1)
        assert (s | r2).repos == (r2, r1)
        assert (r2 | s).repos == (r2, r1)
        for (a, b) in [(None, s), ("s", s)]:
            for (x, y) in [(a, b), (b, a)]:
                with pytest.raises(TypeError):
                    x | y

        # ^ operator
        s = RepoSet(r1, r2, r3)
        assert (s ^ RepoSet(r2, r3)).repos == (r1,)
        assert (s ^ r3).repos == (r2, r1)
        assert (r3 ^ s).repos == (r2, r1)
        for (a, b) in [(None, s), ("s", s)]:
            for (x, y) in [(a, b), (b, a)]:
                with pytest.raises(TypeError):
                    x ^ y

        # - operator
        s = RepoSet(r1, r2)
        assert (s - RepoSet(r1, r2)).repos == ()
        assert (s - r3).repos == (r2, r1)
        assert (s - r2).repos == (r1,)
        for (a, b) in [(None, s), ("s", s)]:
            for (x, y) in [(a, b), (b, a)]:
                with pytest.raises(TypeError):
                    x - y
