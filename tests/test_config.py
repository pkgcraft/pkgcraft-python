import pytest

from pkgcraft.config import Config
from pkgcraft.error import PkgcraftError


class TestConfig:

    def test_repos(self, repo):
        path = repo.path
        config = Config()
        assert not config.repos
        r = config.add_repo(path)
        assert r == config.repos[path]

    def test_add_repo(self, repo):
        path = repo.path
        config = Config()

        # default
        r = config.add_repo(path)
        assert r == config.repos[path]

        # custom
        r = config.add_repo(path, "fake")
        assert r == config.repos["fake"]

        # existing
        with pytest.raises(PkgcraftError, match=f'existing repo: fake'):
            config.add_repo(path, "fake")
