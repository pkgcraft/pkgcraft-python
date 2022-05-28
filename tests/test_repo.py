from pkgcraft import Config


class TestRepo:

    def test_id(self, repo):
        path = repo.path
        config = Config.load()

        # default
        repo = config.add_repo(path)
        assert repo.id == path
        assert str(repo) == path
        assert repr(repo).startswith(f"<Repo '{path}' at 0x")

        # custom
        repo = config.add_repo(path, "fake")
        assert repo.id == "fake"
        assert str(repo) == "fake"
        assert repr(repo).startswith(f"<Repo 'fake: {path}' at 0x")
