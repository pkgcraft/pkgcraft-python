import pytest

from pkgcraft.error import InvalidRepo, PkgcraftError
from pkgcraft.repo import FakeRepo, RepoSet

from .base import BaseRepoTests


@pytest.fixture
def make_repo(make_fake_repo):
    return make_fake_repo


@pytest.fixture
def repo(fake_repo):
    return fake_repo


class TestFakeRepo(BaseRepoTests):

    def test_init(self):
        # invalid args
        with pytest.raises(TypeError):
            FakeRepo(None)

        # no cpvs
        r = FakeRepo('fake')
        assert len(r) == 0

        # empty iterable
        r = FakeRepo('fake', cpvs=[])
        assert len(r) == 0

        # single pkg iterable
        r = FakeRepo('fake', cpvs=['cat/pkg-1'])
        assert len(r) == 1
        assert 'cat/pkg-1' in r

        # multiple pkgs iterable with invalid cpv
        r = FakeRepo('fake', cpvs=['a/b-1', 'c/d-2', '=cat/pkg-1'])
        assert len(r) == 2
        assert 'a/b-1' in r
        assert 'c/d-2' in r
        assert 'cat/pkg-1' not in r

    def test_from_path(self, tmp_path):
        # nonexistent path
        with pytest.raises(InvalidRepo):
            FakeRepo.from_path('/path/to/nonexistent/repo')

        # empty file
        path = tmp_path / 'atoms'
        path.touch()
        r = FakeRepo.from_path(path)
        assert len(r) == 0

        # single pkg file
        path.write_text('cat/pkg-1')
        r = FakeRepo.from_path(path)
        assert len(r) == 1
        assert 'cat/pkg-1' in r

        # file path from string
        r = FakeRepo.from_path(str(path))
        assert len(r) == 1
        assert 'cat/pkg-1' in r

        # multiple pkgs file with invalid cpv
        path.write_text('a/b-1\nc/d-2\n=cat/pkg-1')
        r = FakeRepo.from_path(path)
        assert len(r) == 2
        assert 'a/b-1' in r
        assert 'c/d-2' in r
        assert 'cat/pkg-1' not in r

    def test_extend(self, config, make_fake_repo):
        r = make_fake_repo(config=None)

        # no cpvs
        assert len(r) == 0

        # single cpv
        r.extend(['cat/pkg-1'])
        assert [str(pkg.atom) for pkg in r] == ['cat/pkg-1']

        # multiple cpvs
        r.extend(['a/b-0', 'cat/pkg-2'])
        assert [str(pkg.atom) for pkg in r] == ['a/b-0', 'cat/pkg-1', 'cat/pkg-2']

        # mutability disabled after adding to a config
        config.add_repo(r)
        with pytest.raises(PkgcraftError, match='failed getting mutable repo ref'):
            r.extend(['cat/pkg-3'])

        # mutability disabled after adding to a repo set
        r = make_fake_repo(config=None)
        r.extend(['cat/pkg-1'])
        s = RepoSet(r)
        with pytest.raises(PkgcraftError, match='failed getting mutable repo ref'):
            r.extend(['cat/pkg-2'])
