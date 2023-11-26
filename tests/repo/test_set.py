import pytest

from pkgcraft.config import Config
from pkgcraft.dep import Cpv, Dep, Version
from pkgcraft.error import InvalidRestrict
from pkgcraft.repo import MutableRepoSet, RepoSet

from ..misc import OperatorMap


class BaseTests:
    def test_attrs(self, make_fake_repo):
        r1 = make_fake_repo()
        r2 = make_fake_repo()
        s = self.cls(r1, r2)
        assert str(s)
        assert self.cls.__name__ in repr(s)

    def test_repos(self, make_fake_repo):
        r1 = make_fake_repo()
        r2 = make_fake_repo()
        s = self.cls(r1, r2)
        assert s.repos == [r1, r2]

        r1 = make_fake_repo(priority=1)
        r2 = make_fake_repo(priority=2)
        s = self.cls(r1, r2)
        assert s.repos == [r2, r1]

    def test_pkg_methods(self, make_fake_repo):
        # empty repo set
        s = self.cls()
        assert not s.categories
        assert not s.packages("cat")
        assert not s.versions("cat", "pkg")

        # single pkg
        r1 = make_fake_repo(["cat/pkg-1"])
        r2 = make_fake_repo()
        s = self.cls(r1, r2)
        assert s.categories == ["cat"]
        assert s.packages("cat") == ["pkg"]
        assert s.versions("cat", "pkg") == [Version("1")]

        # multiple new pkg version
        r1 = make_fake_repo(["cat/pkg-1", "cat/pkg-2"])
        r2 = make_fake_repo()
        s = self.cls(r1, r2)
        assert s.categories == ["cat"]
        assert s.packages("cat") == ["pkg"]
        assert s.versions("cat", "pkg") == [Version("1"), Version("2")]

        # matching pkg in other repo
        r1 = make_fake_repo(["cat/pkg-1", "cat/pkg-2"])
        r2 = make_fake_repo(["cat/pkg-1"])
        s = self.cls(r1, r2)
        assert s.categories == ["cat"]
        assert s.packages("cat") == ["pkg"]
        assert s.versions("cat", "pkg") == [Version("1"), Version("2")]

        # new pkg in new category in other repo
        r1 = make_fake_repo(["cat/pkg-1", "cat/pkg-2"])
        r2 = make_fake_repo(["cat/pkg-1", "a/b-1"])
        s = self.cls(r1, r2)
        assert s.categories == ["a", "cat"]
        assert s.packages("a") == ["b"]
        assert s.versions("a", "b") == [Version("1")]

    def test_cmp(self, make_fake_repo):
        for r1, op, r2 in (
            ({"id": "a"}, "<", {"id": "b"}),
            ({"id": "a", "priority": 2}, "<=", {"id": "b", "priority": 1}),
            ({"id": "a"}, "!=", {"id": "b"}),
            ({"id": "b", "priority": 1}, ">=", {"id": "a", "priority": 2}),
            ({"id": "b"}, ">", {"id": "a"}),
        ):
            config = Config()
            op_func = OperatorMap[op]
            err = f"failed {r1} {op} {r2}"
            s1 = self.cls(make_fake_repo(config=config, **r1))
            s2 = self.cls(make_fake_repo(config=config, **r2))
            assert op_func(s1, s2), err

        # verify incompatible type comparisons
        obj = self.cls(make_fake_repo())
        for op, op_func in OperatorMap.items():
            if op == "==":
                assert not op_func(obj, None)
            elif op == "!=":
                assert op_func(obj, None)
            else:
                with pytest.raises(TypeError):
                    op_func(obj, None)

    def test_contains(self, make_fake_repo):
        r1 = make_fake_repo()
        r2 = make_fake_repo()
        pkg1 = r1.create_pkg("cat/pkg-1")
        pkg2 = r2.create_pkg("cat/pkg-1")
        s = self.cls(r1, r2)

        # Cpv strings
        assert "cat/pkg-1" in s
        assert "cat/pkg-2" not in s
        # Cpv objects
        assert Cpv("cat/pkg-1") in s
        assert Cpv("cat/pkg-2") not in s
        # dep strings
        assert "cat/pkg" in s
        assert "cat/pkg2" not in s
        assert "=cat/pkg-1" in s
        assert "=cat/pkg-2" not in s
        # Dep objects
        assert Dep("=cat/pkg-1") in s
        assert Dep("=cat/pkg-2") not in s
        # Pkg objects
        assert pkg1 in s
        assert pkg2 in s
        # Cpv objects
        assert pkg1.cpv in s
        assert pkg2.cpv in s
        # Repo objects
        assert r1 in s
        assert r2 in s
        r3 = make_fake_repo()
        assert r3 not in s

        for obj in (object(), None):
            with pytest.raises(TypeError):
                assert obj in s

    def test_getitem(self, make_fake_repo):
        # empty set
        s = self.cls()
        assert s[:] == s
        with pytest.raises(IndexError):
            s[0]
        with pytest.raises(KeyError):
            s["cat/pkg"]

        # empty repo
        r = make_fake_repo()
        s = self.cls(r)
        assert s[:] == s
        assert s[0] == r
        with pytest.raises(KeyError):
            s["cat/pkg"]

        # single repo with pkg
        r1 = make_fake_repo(id="r1")
        pkg = r1.create_pkg("cat/pkg-1")
        s = self.cls(r1)
        assert s[:] == s
        assert s[0] == r1
        assert s["r1"] == r1
        assert s["cat/pkg"] == pkg
        assert s["cat/pkg-1"] == pkg
        assert s[Cpv("cat/pkg-1")] == pkg
        with pytest.raises(KeyError):
            s["cat/pkg-2"]

        # multiple repos with overlapping pkgs
        r2 = make_fake_repo(id="r2")
        pkg1 = r2.create_pkg("cat/pkg-1")
        pkg2 = r2.create_pkg("cat/pkg-2")
        s = self.cls(r1, r2)
        assert s[:] == s
        assert s[-1] == r2
        assert s["r2"] == r2
        assert s["cat/pkg"] == pkg
        assert s["cat/pkg-1"] == pkg
        assert s["=cat/pkg-1::r2"] == pkg1
        assert s[Dep("=cat/pkg-1::r2")] == pkg1
        assert s["cat/pkg-2"] == pkg2

    def test_bool_and_len(self, make_fake_repo):
        s = self.cls()
        assert not s
        assert len(s) == 0

        s = self.cls(make_fake_repo())
        assert not s
        assert len(s) == 0

        repo = make_fake_repo(["cat/pkg-1"])
        s = self.cls(repo)
        assert s
        assert len(s) == 1

    def test_iter(self, make_fake_repo):
        s = self.cls()

        # calling next() directly on a repo object fails
        with pytest.raises(TypeError):
            next(s)

        # nested calls return equivalent objects
        assert list(iter(s)) == list(iter(iter(s)))

        # empty set
        assert not list(s)

        # single pkg
        r1 = make_fake_repo(["cat/pkg-1"], id="r1", priority=1)
        r2 = make_fake_repo(id="r2", priority=2)
        s = self.cls(r1, r2)
        assert list(map(str, s)) == ["cat/pkg-1::r1"]

        # multiple pkgs
        r1 = make_fake_repo(["cat/pkg-1"], id="r1", priority=1)
        r2 = make_fake_repo(["cat/pkg-2"], id="r2", priority=2)
        s = self.cls(r1, r2)
        assert list(map(str, s)) == ["cat/pkg-2::r2", "cat/pkg-1::r1"]

    def test_iter_restrict(self, make_fake_repo):
        s = self.cls()

        # unsupported object type
        with pytest.raises(TypeError):
            list(s.iter(object()))

        cpv = Cpv("cat/pkg-1")

        # empty repo set -- no matches
        assert not list(s.iter(cpv))

        r1 = make_fake_repo(["cat/pkg-1"], id="r1")
        r2 = make_fake_repo(["cat/pkg-2"], id="r2")
        r3 = make_fake_repo(["cat/pkg-1"], id="r3", priority=1)
        s = self.cls(r1, r2, r3)

        # non-empty repo -- no matches
        nonexistent = Cpv("nonexistent/pkg-1")
        assert not list(s.iter(nonexistent))

        # multiple matches via CPV
        assert list(map(str, s.iter(cpv))) == ["cat/pkg-1::r3", "cat/pkg-1::r1"]

        # single match via package
        pkg = next(s.iter(cpv))
        assert list(s.iter(pkg)) == [pkg]

        # multiple matches via restriction glob
        expected = ["cat/pkg-1::r3", "cat/pkg-1::r1", "cat/pkg-2::r2"]
        assert list(map(str, s.iter("cat/*"))) == expected

        # invalid restriction string
        with pytest.raises(InvalidRestrict):
            list(s.iter("-"))

    def test_set_ops(self, make_fake_repo):
        r1 = make_fake_repo(priority=1)
        r2 = make_fake_repo(priority=2)
        r3 = make_fake_repo(priority=3)

        # &= operator
        s = self.cls(r1, r2, r3)
        s &= self.cls(r1, r2)
        assert isinstance(s, self.cls)
        assert s.repos == [r2, r1]
        s &= r1
        assert s.repos == [r1]
        s &= r3
        assert s.repos == []
        # invalid
        for obj in [None, "s"]:
            with pytest.raises(TypeError):
                s &= obj

        # |= operator
        s = self.cls()
        s |= self.cls(r1, r2)
        assert isinstance(s, self.cls)
        assert s.repos == [r2, r1]
        s |= r3
        assert s.repos == [r3, r2, r1]
        # invalid
        for obj in [None, "s"]:
            with pytest.raises(TypeError):
                s |= obj

        # ^= operator
        s = self.cls(r1, r2, r3)
        s ^= self.cls(r1, r2)
        assert isinstance(s, self.cls)
        assert s.repos == [r3]
        s ^= r3
        assert s.repos == []
        # invalid
        for obj in [None, "s"]:
            with pytest.raises(TypeError):
                s ^= obj

        # -= operator
        s = self.cls(r1, r2, r3)
        s -= self.cls(r1, r2)
        assert isinstance(s, self.cls)
        assert s.repos == [r3]
        s -= r3
        assert s.repos == []
        # invalid
        for obj in [None, "s"]:
            with pytest.raises(TypeError):
                s -= obj

        # & operator
        s = self.cls(r1, r2, r3)
        assert (s & self.cls(r1, r2)).repos == [r2, r1]
        assert (s & r3).repos == [r3]
        assert (r3 & s).repos == [r3]
        assert isinstance(s & s, self.cls)
        # invalid
        for obj in [None, "s"]:
            for x, y in [(s, obj), (obj, s)]:
                with pytest.raises(TypeError):
                    x & y

        # | operator
        s = self.cls(r1)
        assert (s | self.cls(r2, r3)).repos == [r3, r2, r1]
        assert (s | r2).repos == [r2, r1]
        assert (r2 | s).repos == [r2, r1]
        assert isinstance(s | s, self.cls)
        # invalid
        for obj in [None, "s"]:
            for x, y in [(s, obj), (obj, s)]:
                with pytest.raises(TypeError):
                    x | y

        # ^ operator
        s = self.cls(r1, r2, r3)
        assert (s ^ self.cls(r2, r3)).repos == [r1]
        assert (s ^ r3).repos == [r2, r1]
        assert (r3 ^ s).repos == [r2, r1]
        assert isinstance(s ^ s, self.cls)
        # invalid
        for obj in [None, "s"]:
            for x, y in [(s, obj), (obj, s)]:
                with pytest.raises(TypeError):
                    x ^ y

        # - operator
        s = self.cls(r1, r2)
        assert (s - self.cls(r1, r2)).repos == []
        assert (s - r3).repos == [r2, r1]
        assert (s - r2).repos == [r1]
        assert isinstance(s - s, self.cls)
        # invalid
        for obj in [None, "s"]:
            for x, y in [(s, obj), (obj, s)]:
                with pytest.raises(TypeError):
                    x - y


class TestRepoSet(BaseTests):
    cls = RepoSet

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


class TestMutableRepoSet(BaseTests):
    cls = MutableRepoSet

    def test_hash(self):
        with pytest.raises(TypeError):
            hash(MutableRepoSet())
