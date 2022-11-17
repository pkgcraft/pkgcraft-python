import pytest

from pkgcraft.atom import Atom, Cpv
from pkgcraft.config import Config
from pkgcraft.error import IndirectInit
from pkgcraft.repo import Repo

from ..misc import OperatorMap


class TestRepo:

    def test_init(self):
        with pytest.raises(IndirectInit):
            Repo()

    def test_attrs(self, config, raw_repo):
        path = raw_repo.path
        r = config.add_repo_path(path)

        # default
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
        # empty repo
        assert not repo.categories
        assert not repo.packages('cat')
        assert not repo.versions('cat', 'pkg')

        # create ebuild
        repo.create_ebuild('cat1/pkga-1')
        assert repo.categories == ('cat1',)
        assert repo.packages('cat1') == ('pkga',)
        assert repo.versions('cat1', 'pkga') == ('1',)

        # create new ebuild version
        repo.create_ebuild("cat1/pkga-2")
        assert repo.categories == ('cat1',)
        assert repo.packages('cat1') == ('pkga',)
        assert repo.versions('cat1', 'pkga') == ('1', '2')

        # create new pkg
        repo.create_ebuild("cat1/pkgb-1")
        assert repo.categories == ('cat1',)
        assert repo.packages('cat1') == ('pkga', 'pkgb')

        # create new pkg in new category
        repo.create_ebuild("cat2/pkga-1")
        assert repo.categories == ('cat1', 'cat2')
        assert repo.packages('cat2') == ('pkga',)

    def test_cmp(self, repo):
        assert repo == repo
        path = repo.path

        for (r1_args, op, r2_args) in (
                (['a'], '<', ['b']),
                (['a', 2], '<=', ['b', 1]),
                (['a'], '!=', ['b']),
                (['b', 1], '>=', ['a', 2]),
                (['b'], '>', ['a']),
                ):
            config = Config()
            op_func = OperatorMap[op]
            r1 = config.add_repo_path(path, *r1_args)
            r2 = config.add_repo_path(path, *r2_args)
            assert op_func(r1, r2), f'failed {r1_args} {op} {r2_args}'

    def test_hash(self, config, raw_repo):
        r1 = config.add_repo_path(raw_repo.path)
        r2 = config.add_repo_path(raw_repo.path, "fake")
        assert len({r1, r2}) == 2

    def test_contains(self, repo):
        repo.create_ebuild("cat/pkg-1")
        assert 'cat/pkg' in repo
        assert 'cat/pkg2' not in repo
        assert Cpv('cat/pkg-1') in repo
        assert Cpv('cat/pkg-2') not in repo
        assert Atom('=cat/pkg-1') in repo
        assert Atom('=cat/pkg-2') not in repo

        for obj in (object(), None):
            with pytest.raises(TypeError):
                assert obj in repo

    def test_getitem(self, repo):
        pkg = repo.create_pkg('cat/pkg-1')
        assert pkg == repo['cat/pkg-1']
        assert pkg == repo[Cpv('cat/pkg-1')]

        for obj in ('cat/pkg-2', Cpv('cat/pkg-3')):
            with pytest.raises(KeyError):
                repo[obj]

    def test_bool_and_len(self, repo):
        # empty repo
        assert not repo
        assert len(repo) == 0

        # create ebuild
        repo.create_ebuild("cat/pkg-1")
        assert repo
        assert len(repo) == 1

        # recreate ebuild
        repo.create_ebuild("cat/pkg-1")
        assert repo
        assert len(repo) == 1

        # create new ebuild version
        repo.create_ebuild("cat/pkg-2")
        assert repo
        assert len(repo) == 2
