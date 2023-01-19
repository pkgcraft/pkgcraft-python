import pytest

from pkgcraft.atom import Atom, Cpv
from pkgcraft.config import Config
from pkgcraft.error import InvalidRestrict

from ..misc import OperatorMap


class BaseRepoTests:
    def test_attrs_base(self, make_repo):
        r = make_repo(id="fake")

        # default
        assert r.id == "fake"
        assert str(r) == "fake"

    def test_pkg_methods_base(self, repo):
        # empty repo
        assert not repo.categories
        assert not repo.packages("cat")
        assert not repo.versions("cat", "pkg")

        # create pkg
        repo.create_pkg("cat1/pkga-1")
        assert repo.categories == ("cat1",)
        assert repo.packages("cat1") == ("pkga",)
        assert repo.versions("cat1", "pkga") == ("1",)

        # create new pkg version
        repo.create_pkg("cat1/pkga-2")
        assert repo.categories == ("cat1",)
        assert repo.packages("cat1") == ("pkga",)
        assert repo.versions("cat1", "pkga") == ("1", "2")

        # create new pkg
        repo.create_pkg("cat1/pkgb-1")
        assert repo.categories == ("cat1",)
        assert repo.packages("cat1") == ("pkga", "pkgb")

        # create new pkg in new category
        repo.create_pkg("cat2/pkga-1")
        assert repo.categories == ("cat1", "cat2")
        assert repo.packages("cat2") == ("pkga",)

    def test_cmp_base(self, make_repo):
        for (r1_args, op, r2_args) in (
            (["a"], "<", ["b"]),
            (["a", 2], "<=", ["b", 1]),
            (["a"], "!=", ["b"]),
            (["b", 1], ">=", ["a", 2]),
            (["b"], ">", ["a"]),
        ):
            config = Config()
            op_func = OperatorMap[op]
            r1 = make_repo(None, *r1_args, config=config)
            r2 = make_repo(None, *r2_args, config=config)
            assert op_func(r1, r2), f"failed {r1_args} {op} {r2_args}"

    def test_hash_base(self, config, make_repo):
        r1 = make_repo()
        r2 = make_repo()
        assert len({r1, r2}) == 2

    def test_contains_base(self, make_repo):
        r1 = make_repo()
        r2 = make_repo()
        pkg1 = r1.create_pkg("cat/pkg-1")
        pkg2 = r2.create_pkg("cat/pkg-1")

        # Cpv strings
        assert "cat/pkg-1" in r1
        assert "cat/pkg-2" not in r1
        # Cpv objects
        assert Cpv("cat/pkg-1") in r1
        assert Cpv("cat/pkg-2") not in r1
        # Atom strings
        assert "cat/pkg" in r1
        assert "cat/pkg2" not in r1
        assert "=cat/pkg-1" in r1
        assert "=cat/pkg-2" not in r1
        # Atom objects
        assert Atom("=cat/pkg-1") in r1
        assert Atom("=cat/pkg-2") not in r1
        # Pkg objects
        assert pkg1 in r1
        assert pkg2 not in r1
        assert pkg1 not in r2
        assert pkg2 in r2
        # Pkg atoms
        assert pkg1.atom in r1
        assert pkg2.atom in r1

        for obj in (object(), None):
            with pytest.raises(TypeError):
                assert obj in r1

    def test_getitem_base(self, repo):
        pkg = repo.create_pkg("cat/pkg-1")
        assert pkg == repo["cat/pkg-1"]
        assert pkg == repo[Cpv("cat/pkg-1")]

        for obj in ("cat/pkg-2", Cpv("cat/pkg-3")):
            with pytest.raises(KeyError):
                repo[obj]

    def test_bool_and_len_base(self, repo):
        # empty repo
        assert not repo
        assert len(repo) == 0

        # create pkg
        repo.create_pkg("cat/pkg-1")
        assert repo
        assert len(repo) == 1

        # recreate pkg
        repo.create_pkg("cat/pkg-1")
        assert repo
        assert len(repo) == 1

        # create new pkg version
        repo.create_pkg("cat/pkg-2")
        assert repo
        assert len(repo) == 2

    def test_iter_base(self, repo):
        # calling next() directly on a repo object fails
        with pytest.raises(TypeError):
            next(repo)

        # multiple iter() calls free underlying pointer
        iter(repo)
        iter(repo)

        # empty repo
        assert not list(repo)

        # single pkg
        repo.create_pkg("cat/pkg-1")
        assert list(map(str, repo)) == ["cat/pkg-1::fake"]

        # multiple pkgs
        repo.create_pkg("cat/pkg-2")
        assert list(map(str, repo)) == ["cat/pkg-1::fake", "cat/pkg-2::fake"]

    def test_iter_restrict_base(self, repo):
        # non-None argument required
        with pytest.raises(TypeError):
            repo.iter_restrict(None)

        # unsupported object type
        with pytest.raises(TypeError):
            list(repo.iter_restrict(object()))

        cpv = Cpv("cat/pkg-1")

        # empty repo -- no matches
        assert not list(repo.iter_restrict(cpv))

        pkg1 = repo.create_pkg("cat/pkg-1")
        pkg2 = repo.create_pkg("cat/pkg-2")

        # non-empty repo -- no matches
        nonexistent = Cpv("nonexistent/pkg-1")
        assert not list(repo.iter_restrict(nonexistent))

        # single match via Cpv
        assert list(repo.iter_restrict(cpv)) == [pkg1]

        # single match via package
        assert list(repo.iter_restrict(pkg1)) == [pkg1]

        # multiple matches via restriction glob
        assert list(repo.iter_restrict("cat/*")) == [pkg1, pkg2]

        # invalid restriction string
        with pytest.raises(InvalidRestrict):
            list(repo.iter_restrict("-"))
