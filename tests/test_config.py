from pkgcraft.config import Config


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
