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
        r = config.add_repo_path(path, "fake")
        assert r == config.repos["fake"]

        # existing
        with pytest.raises(PkgcraftError, match='existing repo: fake'):
            config.add_repo_path(path, "fake")
