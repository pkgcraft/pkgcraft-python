import textwrap

import pytest

from pkgcraft.error import PkgcraftError
from pkgcraft.repo import FakeRepo, RepoSet


class TestConfig:

    def test_repos(self, config, raw_repo):
        path = raw_repo.path
        assert not config.repos
        r = config.add_repo_path(path)
        assert r == config.repos[str(path)]

        d = {x: config.repos[x] for x in config.repos}
        assert repr(config.repos) == repr(d)
        assert str(config.repos) == str(d)
        assert config.repos
        assert len(config.repos) == 1

    def test_add_repo_path_ebuild(self, config, raw_repo):
        path = raw_repo.path

        # default
        r = config.add_repo_path(path)
        assert r == config.repos[str(path)]

        # custom
        r = config.add_repo_path(path, 'fake')
        assert r == config.repos['fake']

        # existing
        with pytest.raises(PkgcraftError, match='existing repo: fake'):
            config.add_repo_path(path, 'fake')

        # nonexistent
        with pytest.raises(PkgcraftError, match='nonexistent repo path'):
            config.add_repo_path('/path/to/nonexistent/repo')

    def test_add_repo_path_fake(self, config, tmp_path):
        # empty file
        f = tmp_path / "repo1"
        f.touch()
        r = config.add_repo_path(f)
        assert r == config.repos[str(f)]
        assert len(r) == 0

        # cpvs
        f = tmp_path / "repo2"
        f.write_text(textwrap.dedent(f"""
            cat/pkg-1
            cat/pkg-2
            a/b-0
        """))
        r = config.add_repo_path(f)
        assert len(r) == 3

    def test_add_repo(self, config):
        assert not config.repos
        r1 = FakeRepo([], id='r1', priority=1)
        r2 = FakeRepo([], id='r2', priority=2)
        config.add_repo(r1)
        config.add_repo(r2)
        assert config.repos == {'r2': r2, 'r1': r1}

    def test_repo_sets(self, config, make_ebuild_repo, make_fake_repo):
        r1 = make_ebuild_repo(config=config)
        r2 = make_fake_repo(config=config)
        assert config.repos.all == RepoSet(r1, r2)
        assert config.repos.ebuild == RepoSet(r1)

    def test_load_repos_conf(self, config, raw_repo, tmp_path):
        repo_path = raw_repo.path

        # nonexistent
        f = '/path/to/nonexistent/file'
        with pytest.raises(PkgcraftError, match=f'config error: .* "{f}": No such file or directory'):
            config.load_repos_conf(f)

        # empty file
        f = tmp_path / "file"
        f.touch()
        config.load_repos_conf(f)
        assert not config.repos

        # no sections
        f.write_text(textwrap.dedent(f"""
            location = {repo_path}
        """))
        config.load_repos_conf(f)
        assert not config.repos

        # bad ini format
        f.write_text(textwrap.dedent(f"""
            [test
            location = {repo_path}
        """))
        with pytest.raises(PkgcraftError, match=f'config error: invalid repos.conf file: "{f}"'):
            config.load_repos_conf(f)

        # file path
        f.write_text(textwrap.dedent(f"""
            [test]
            location = {repo_path}
        """))
        config.load_repos_conf(f)
        assert set(config.repos) == {'test'}

        # reloading causes an existence error
        with pytest.raises(PkgcraftError, match='config error: existing repo: test'):
            config.load_repos_conf(f)

        # dir path
        dir_path = tmp_path / "dir"
        dir_path.mkdir()
        f = dir_path / "1.conf"
        f.write_text(textwrap.dedent(f"""
            [test1]
            location = {repo_path}
        """))
        f = dir_path / "2.conf"
        f.write_text(textwrap.dedent(f"""
            [test2]
            location = {repo_path}
        """))
        config.load_repos_conf(dir_path)
        assert set(config.repos) == {'test', 'test1', 'test2'}
