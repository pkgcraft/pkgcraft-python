from pkgcraft import Config


class TestRepo:

    def test_id(self, repo):
        path = repo.path
        config = Config.load()

        # default
        config.add_repo(path)
        repo = config.repos[path]
        assert repo.id == path
        assert str(repo) == path
        assert repr(repo).startswith(f"<Repo '{path}: {path}' at 0x")

        # custom
        config.add_repo(path, "fake")
        repo = config.repos["fake"]
        assert repo.id == "fake"
        assert str(repo) == "fake"
        assert repr(repo).startswith(f"<Repo 'fake: {path}' at 0x")
