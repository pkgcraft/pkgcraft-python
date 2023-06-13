import textwrap

import pytest

from pkgcraft.config import Config
from pkgcraft.error import ConfigError, InvalidRepo
from pkgcraft.repo import FakeRepo, RepoSet


class TestConfig:
    def test_repos(self, config, raw_ebuild_repo):
        path = str(raw_ebuild_repo.path)
        assert not config.repos
        r = config.add_repo(path)
        assert config.repos[path] == r
        assert config.repos.get(path) == r
        assert path in config.repos
        assert config.repos.get("nonexistent") is None

        d = {x: config.repos[x] for x in config.repos}
        assert repr(config.repos) == repr(d)
        assert str(config.repos) == str(d)
        assert config.repos
        assert len(config.repos) == 1

    def test_add_repo_path_ebuild(self, raw_ebuild_repo):
        path = raw_ebuild_repo.path

        # default
        config = Config()
        r = config.add_repo(path)
        assert r == config.repos[str(path)]

        # custom
        config = Config()
        r = config.add_repo(path, "fake")
        assert r == config.repos["fake"]

        # existing
        with pytest.raises(ConfigError, match="existing repos: fake"):
            config.add_repo(path, "fake")

        # existing using a different id
        with pytest.raises(ConfigError, match="existing repos: existing"):
            config.add_repo(path, "existing")

        # nonexistent
        with pytest.raises(InvalidRepo):
            config.add_repo("/path/to/nonexistent/repo")

    def test_add_repo_path_fake(self, config, tmp_path):
        # empty file
        f = tmp_path / "repo1"
        f.touch()
        r = config.add_repo(f)
        assert r == config.repos[str(f)]
        assert len(r) == 0

        # cpvs
        f = tmp_path / "repo2"
        f.write_text(
            textwrap.dedent(
                """
            cat/pkg-1
            cat/pkg-2
            a/b-0
        """
            )
        )
        r = config.add_repo(f)
        assert len(r) == 3

    def test_add_repo(self, config):
        assert not config.repos
        r1 = FakeRepo(id="r1", priority=1)
        r2 = FakeRepo(id="r2", priority=2)
        config.add_repo(r1)
        config.add_repo(r2)
        assert config.repos != {}
        assert config.repos == {"r2": r2, "r1": r1}

        # re-adding a repo fails
        with pytest.raises(ConfigError, match="existing repos: r1"):
            config.add_repo(r1)

    def test_repo_sets(self, config, make_ebuild_repo, make_fake_repo):
        # empty
        assert config.repos.all == RepoSet()
        assert config.repos.ebuild == RepoSet()

        # populated
        r1 = make_ebuild_repo(config=config)
        r2 = make_fake_repo(config=config)
        assert config.repos.all == RepoSet(r1, r2)
        assert config.repos.ebuild == RepoSet(r1)

    def test_load_portage_conf(self, config, make_raw_ebuild_repo, tmp_path):
        repo_path = make_raw_ebuild_repo().path
        conf_path = str(tmp_path)
        f = tmp_path / "repos.conf"

        # nonexistent
        with pytest.raises(ConfigError, match=f"config error: nonexistent portage config path: .+"):
            config.load_portage_conf(tmp_path / "nonexistent")

        # empty file
        f.touch()
        config.load_portage_conf(conf_path)
        assert not config.repos

        # no sections
        f.write_text(
            textwrap.dedent(
                f"""
            location = {repo_path}
        """
            )
        )
        config.load_portage_conf(conf_path)
        assert not config.repos

        # bad ini format
        f.write_text(
            textwrap.dedent(
                f"""
            [test
            location = {repo_path}
        """
            )
        )
        with pytest.raises(ConfigError, match=f'config error: invalid repos.conf file: "{f}"'):
            config.load_portage_conf(conf_path)

        # file path
        repo_path = make_raw_ebuild_repo(id="test1").path
        f.write_text(
            textwrap.dedent(
                f"""
            [test1]
            location = {repo_path}
        """
            )
        )
        config.load_portage_conf(conf_path)
        assert set(config.repos) == {"test1"}

        # reloading causes an existence error
        with pytest.raises(ConfigError, match="existing repos: test1"):
            config.load_portage_conf(conf_path)

        # reloading using a different id still causes an error
        f.write_text(
            textwrap.dedent(
                f"""
            [existing]
            location = {repo_path}
        """
            )
        )
        with pytest.raises(ConfigError, match="existing repos: existing"):
            config.load_portage_conf(conf_path)

        # dir path
        conf_path = tmp_path / "dir"
        dir_path = conf_path / "repos.conf"
        dir_path.mkdir(parents=True)
        f = dir_path / "2.conf"
        r2_path = make_raw_ebuild_repo(id="test2").path
        f.write_text(
            textwrap.dedent(
                f"""
            [test2]
            location = {r2_path}
        """
            )
        )
        f = dir_path / "3.conf"
        r3_path = make_raw_ebuild_repo(id="test3").path
        f.write_text(
            textwrap.dedent(
                f"""
            [test3]
            location = {r3_path}
            priority = 1
        """
            )
        )
        config.load_portage_conf(conf_path)
        assert set(config.repos) == {"test3", "test1", "test2"}
