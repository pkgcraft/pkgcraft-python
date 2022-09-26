import pytest

from pkgcraft.config import Config
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
