import pytest

from pkgcraft.atom import Cpv
from pkgcraft.config import Config
from pkgcraft.error import InvalidRestrict
from pkgcraft.repo import RepoSet

from ..misc import OperatorMap


class TestRepoSet:

    def test_attrs(self, make_ebuild_repo):
        r1 = make_ebuild_repo()
        r2 = make_ebuild_repo()
        s = RepoSet(r1, r2)
        assert str(s)
        assert repr(s).startswith('<RepoSet ')

    def test_repos(self, make_ebuild_repo):
        r1 = make_ebuild_repo()
        r2 = make_ebuild_repo()
        s = RepoSet(r1, r2)
        assert s.repos == (r1, r2)

        r1 = make_ebuild_repo(priority=1)
        r2 = make_ebuild_repo(priority=2)
        s = RepoSet(r1, r2)
        assert s.repos == (r2, r1)

    def test_pkg_methods(self, make_ebuild_repo):
        r1 = make_ebuild_repo()
        r2 = make_ebuild_repo()

        # empty repo set
        s = RepoSet()
        assert not s.categories
        assert not s.packages('cat')
        assert not s.versions('cat', 'pkg')

        # create ebuild
        s = RepoSet(r1, r2)
        r1.create_ebuild('cat/pkg-1')
        assert s.categories == ('cat',)
        assert s.packages('cat') == ('pkg',)
        assert s.versions('cat', 'pkg') == ('1',)

        # create new ebuild version
        r1.create_ebuild('cat/pkg-2')
        assert s.categories == ('cat',)
        assert s.packages('cat') == ('pkg',)
        assert s.versions('cat', 'pkg') == ('1', '2')

        # create matching pkg in other repo
        r2.create_ebuild('cat/pkg-1')
        assert s.categories == ('cat',)
        assert s.packages('cat') == ('pkg',)
        assert s.versions('cat', 'pkg') == ('1', '2')

        # create new pkg in new category in other repo
        r2.create_ebuild('a/b-1')
        assert s.categories == ('a', 'cat')
        assert s.packages('a') == ('b',)
        assert s.versions('a', 'b') == ('1',)

    def test_cmp(self, make_ebuild_repo):
        for (r1, op, r2) in (
                ({'id': 'a'}, '<', {'id': 'b'}),
                ({'id': 'a', 'priority': 2}, '<=', {'id': 'b', 'priority': 1}),
                ({'id': 'a'}, '!=', {'id': 'b'}),
                ({'id': 'b', 'priority': 1}, '>=', {'id': 'a', 'priority': 2}),
                ({'id': 'b'}, '>', {'id': 'a'}),
                ):
            config = Config()
            op_func = OperatorMap[op]
            err = f'failed {r1} {op} {r2}'
            s1 = RepoSet(make_ebuild_repo(config=config, **r1))
            s2 = RepoSet(make_ebuild_repo(config=config, **r2))
            assert op_func(s1, s2), err

    def test_hash(self, make_ebuild_repo):
        r1 = make_ebuild_repo()
        r2 = make_ebuild_repo()
        r3 = make_ebuild_repo()

        # equal sets
        s1 = RepoSet(r1, r2)
        s2 = RepoSet(r2, r1)
        assert s2 in {s1}

        # unequal sets
        s3 = RepoSet(r1, r3)
        assert s1 not in {s3}

    def test_bool_and_len(self, repo):
        s = RepoSet()
        assert not s
        assert len(s) == 0

        s = RepoSet(repo)
        assert not s
        assert len(s) == 0

        repo.create_pkg('cat/pkg-1')
        s = RepoSet(repo)
        assert s
        assert len(s) == 1

    def test_iter(self, make_ebuild_repo):
        r1 = make_ebuild_repo(priority=1)
        r2 = make_ebuild_repo(priority=2)
        s = RepoSet(r1, r2)

        # calling next() directly on a repo object fails
        with pytest.raises(TypeError):
            next(s)

        # empty set
        assert not list(iter(s))

        # single pkg
        pkg1 = r1.create_pkg('cat/pkg-1')
        assert list(iter(s)) == [pkg1]

        # multiple pkgs
        pkg2 = r2.create_pkg('cat/pkg-2')
        assert list(iter(s)) == [pkg2, pkg1]

    def test_iter_restrict(self, make_ebuild_repo):
        r1 = make_ebuild_repo()
        r2 = make_ebuild_repo()
        r3 = make_ebuild_repo(priority=1)
        s = RepoSet(r1, r2, r3)

        # non-None argument required
        with pytest.raises(TypeError):
            s.iter_restrict(None)

        # unsupported object type
        with pytest.raises(TypeError):
            list(s.iter_restrict(object()))

        cpv = Cpv('cat/pkg-1')

        # empty repo -- no matches
        assert not list(s.iter_restrict(cpv))

        pkg1 = r1.create_pkg('cat/pkg-1')
        pkg2 = r2.create_pkg('cat/pkg-2')
        pkg3 = r3.create_pkg('cat/pkg-1')

        # non-empty repo -- no matches
        nonexistent = Cpv('nonexistent/pkg-1')
        assert not list(s.iter_restrict(nonexistent))

        # multiple matches via CPV
        assert list(s.iter_restrict(cpv)) == [pkg3, pkg1]

        # single match via package
        assert list(s.iter_restrict(pkg1)) == [pkg1]

        # multiple matches via restriction glob
        assert list(s.iter_restrict('cat/*')) == [pkg3, pkg1, pkg2]

        # invalid restriction string
        with pytest.raises(InvalidRestrict):
            list(s.iter_restrict('-'))

    def test_set_ops(self, make_ebuild_repo):
        r1 = make_ebuild_repo(priority=1)
        r2 = make_ebuild_repo(priority=2)
        r3 = make_ebuild_repo(priority=3)

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

        # | operator
        s = RepoSet(r1)
        assert (s | RepoSet(r2, r3)).repos == (r3, r2, r1)
        assert (s | r2).repos == (r2, r1)
        assert (r2 | s).repos == (r2, r1)

        # ^ operator
        s = RepoSet(r1, r2, r3)
        assert (s ^ RepoSet(r2, r3)).repos == (r1,)
        assert (s ^ r3).repos == (r2, r1)
        assert (r3 ^ s).repos == (r2, r1)

        # - operator
        s = RepoSet(r1, r2)
        assert (s - RepoSet(r1, r2)).repos == ()
        assert (s - r3).repos == (r2, r1)
        assert (s - r2).repos == (r1,)
        with pytest.raises(TypeError):
            r2 - s
