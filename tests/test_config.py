import textwrap

import pytest

from pkgcraft.config import Config
from pkgcraft.error import PkgcraftError


class TestConfig:

    def test_repos(self, repo):
        path = repo.path
        config = Config()
        assert not config.repos
        r = config.add_repo_path(path)
        assert r == config.repos[str(path)]

    def test_add_repo_path(self, repo):
        path = repo.path
        config = Config()

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

    def test_load_repos_conf(self, repo, tmp_path):
        repo_path = repo.path
        config = Config()

        # nonexistent
        f = '/path/to/nonexistent/file'
        with pytest.raises(PkgcraftError, match=f'config error: .* "{f}": No such file or directory'):
            config.load_repos_conf(f)

        # file path
        file = tmp_path / "file"
        file.write_text(textwrap.dedent(f"""
            [test]
            location = {repo_path}
        """))
        config.load_repos_conf(file)
        assert set(config.repos) == {'test'}

        # reloading causes an existence error
        with pytest.raises(PkgcraftError, match='config error: existing repo: test'):
            config.load_repos_conf(file)

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
