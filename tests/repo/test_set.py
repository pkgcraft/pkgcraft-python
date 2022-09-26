import pytest

from pkgcraft.atom import Cpv
from pkgcraft.config import Config
from pkgcraft.error import InvalidRestrict
from pkgcraft.repo import RepoSet

from ..misc import OperatorMap


class TestRepoSet:

    def test_attrs(self, make_repo):
        r1 = make_repo()
        r2 = make_repo()
        s = RepoSet([r1, r2])
        assert str(s)
        assert repr(s).startswith("<RepoSet ")

    def test_repos(self, make_repo):
        r1 = make_repo()
        r2 = make_repo()
        s = RepoSet([r1, r2])
        assert s.repos == (r1, r2)

    def test_cmp(self, make_repo):
        for (r1, op, r2) in (
                ({'id': 'a'}, '<', {'id': 'b'}),
                ({'id': 'b', 'priority': 1}, '<=', {'id': 'a', 'priority': 2}),
                ({'id': 'a'}, '!=', {'id': 'b'}),
                ({'id': 'a', 'priority': 2}, '>=', {'id': 'b', 'priority': 1}),
                ({'id': 'b'}, '>', {'id': 'a'}),
                ):
            config = Config()
            op_func = OperatorMap[op]
            err = f"failed {r1} {op} {r2}"
            s1 = RepoSet([make_repo(config=config, **r1)])
            s2 = RepoSet([make_repo(config=config, **r2)])
            assert op_func(s1, s2), err

    def test_hash(self, make_repo):
        r1 = make_repo()
        r2 = make_repo()
        r3 = make_repo()

        # equal sets
        s1 = RepoSet([r1, r2])
        s2 = RepoSet([r2, r1])
        assert s2 in {s1}

        # unequal sets
        s3 = RepoSet([r1, r3])
        assert s1 not in {s3}

    def test_bool(self, repo):
        assert not RepoSet([])
        assert RepoSet([repo])

    def test_iter(self, make_repo):
        r1 = make_repo()
        r2 = make_repo()
        s = RepoSet([r1, r2])

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
        assert list(iter(s)) == [pkg1, pkg2]

    def test_iter_restrict(self, make_repo):
        r1 = make_repo()
        r2 = make_repo()
        s = RepoSet([r1, r2])

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

        # non-empty repo -- no matches
        nonexistent = Cpv('nonexistent/pkg-1')
        assert not list(s.iter_restrict(nonexistent))

        # single match via Cpv
        assert list(s.iter_restrict(cpv)) == [pkg1]

        # single match via package
        assert list(s.iter_restrict(pkg1)) == [pkg1]

        # multiple matches via restriction glob
        assert list(s.iter_restrict('cat/*')) == [pkg1, pkg2]

        # invalid restriction string
        with pytest.raises(InvalidRestrict):
            list(s.iter_restrict('-'))

    def test_set_ops(self, make_repo):
        r1 = make_repo()
        r2 = make_repo()
        r3 = make_repo()

        # &= operator
        s = RepoSet([r1, r2, r3])
        s &= RepoSet([r1, r2])
        assert s.repos == (r1, r2)
        s &= r1
        assert s.repos == (r1,)
        s &= r3
        assert s.repos == ()

        # |= operator
        s = RepoSet([])
        s |= RepoSet([r1, r2])
        assert s.repos == (r1, r2)
        s |= r3
        assert s.repos == (r1, r2, r3)

        # ^= operator
        s = RepoSet([r1, r2, r3])
        s ^= RepoSet([r1, r2])
        assert s.repos == (r3,)
        s ^= r3
        assert s.repos == ()

        # -= operator
        s = RepoSet([r1, r2, r3])
        s -= RepoSet([r1, r2])
        assert s.repos == (r3,)
        s -= r3
        assert s.repos == ()

        # & operator
        s = RepoSet([r1, r2, r3])
        assert (s & RepoSet([r1, r2])).repos == (r1, r2)
        assert (s & r3).repos == (r3,)

        # | operator
        s = RepoSet([r1])
        assert (s | RepoSet([r2, r3])).repos == (r1, r2, r3)
        assert (s | r2).repos == (r1, r2)

        # ^ operator
        s = RepoSet([r1, r2, r3])
        assert (s ^ RepoSet([r2, r3])).repos == (r1,)
        assert (s ^ r3).repos == (r1, r2)

        # - operator
        s = RepoSet([r1, r2])
        assert (s - RepoSet([r1, r2])).repos == ()
        assert (s - r3).repos == (r1, r2)
        assert (s - r2).repos == (r1,)
