import pytest

from pkgcraft.config import Config
from pkgcraft.error import PkgcraftError
from pkgcraft.repo import Repo

from ..misc import OperatorMap


class TestRepo:

    def test_init(self):
        with pytest.raises(PkgcraftError, match="doesn't support regular creation"):
            Repo()

    def test_attrs(self, repo):
        path = repo.path
        config = Config()

        # default
        r = config.add_repo_path(path)
        assert r.id == path
        assert str(r) == path
        assert repr(r).startswith(f"<EbuildRepo '{path}' at 0x")

        # custom
        r = config.add_repo_path(path, "fake")
        assert r.id == "fake"
        assert str(r) == "fake"
        assert repr(r).startswith(f"<EbuildRepo 'fake' at 0x")

    def test_cmp(self, repo):
        path = repo.path
        config = Config()
        r = config.add_repo_path(path)
        assert r == r

        for (r1, op, r2) in (
                (['a'], '<', ['b']),
                (['b', 1], '<=', ['a', 2]),
                (['a'], '!=', ['b']),
                (['a', 2], '>=', ['b', 1]),
                (['b'], '>', ['a']),
                ):
            config = Config()
            op_func = OperatorMap[op]
            err = f"failed {r1} {op} {r2}"
            assert op_func(config.add_repo_path(path, *r1), config.add_repo_path(path, *r2)), err

    def test_hash(self, repo):
        path = repo.path
        config = Config()
        r1 = config.add_repo_path(path)
        r2 = config.add_repo_path(path, "fake")
        assert len({r1, r2}) == 2

    def test_len(self, repo):
        path = repo.path
        config = Config()
        r = config.add_repo_path(path)

        # empty repo
        assert len(r) == 0

        # create ebuild
        repo.create_ebuild("cat/pkg-1")
        assert len(r) == 1

        # recreate ebuild
        repo.create_ebuild("cat/pkg-1")
        assert len(r) == 1

        # create new ebuild version
        repo.create_ebuild("cat/pkg-2")
        assert len(r) == 2
