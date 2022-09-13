import pytest

from pkgcraft.atom import Atom, Cpv
from pkgcraft.config import Config
from pkgcraft.repo import Repo

from ..misc import OperatorMap


class TestRepo:

    def test_init(self):
        with pytest.raises(RuntimeError, match="doesn't support manual construction"):
            Repo()

    def test_attrs(self, repo):
        path = repo.path
        config = Config()

        # default
        r = config.add_repo_path(path)
        assert r.id == str(path)
        assert r.path == str(path)
        assert str(r) == str(path)
        assert repr(r).startswith(f"<EbuildRepo '{path}' at 0x")

        # custom
        r = config.add_repo_path(path, "fake")
        assert r.id == "fake"
        assert r.path == str(path)
        assert str(r) == "fake"
        assert repr(r).startswith(f"<EbuildRepo 'fake' at 0x")

    def test_pkg_methods(self, repo):
        path = repo.path
        config = Config()
        r = config.add_repo_path(path)

        # empty repo
        assert not r.categories
        assert not r.packages('cat')
        assert not r.versions('cat', 'pkg')

        # create ebuild
        repo.create_ebuild('cat1/pkga-1')
        assert r.categories == ('cat1',)
        assert r.packages('cat1') == ('pkga',)
        assert r.versions('cat1', 'pkga') == ('1',)

        # create new ebuild version
        repo.create_ebuild("cat1/pkga-2")
        assert r.categories == ('cat1',)
        assert r.packages('cat1') == ('pkga',)
        assert r.versions('cat1', 'pkga') == ('1', '2')

        # create new pkg
        repo.create_ebuild("cat1/pkgb-1")
        assert r.categories == ('cat1',)
        assert r.packages('cat1') == ('pkga', 'pkgb')

        # create new pkg in new category
        repo.create_ebuild("cat2/pkga-1")
        assert r.categories == ('cat1', 'cat2')
        assert r.packages('cat2') == ('pkga',)

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

    def test_contains(self, repo):
        path = repo.path
        config = Config()
        r = config.add_repo_path(path)
        repo.create_ebuild("cat/pkg-1")
        assert 'cat/pkg' in r
        assert 'cat/pkg2' not in r
        assert Cpv('cat/pkg-1') in r
        assert Cpv('cat/pkg-2') not in r
        assert Atom('=cat/pkg-1') in r
        assert Atom('=cat/pkg-2') not in r

        for obj in (object(), None):
            with pytest.raises(TypeError):
                assert obj in r

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
