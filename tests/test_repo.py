import pkgcraft


class TestRepo:

    def test_id(self, repo):
        path = repo.path
        config = pkgcraft.config.load()

        # default
        repo = config.add_repo(path)
        assert repo == config.repos[path]
        assert repo.id == path
        assert str(repo) == path
        assert repr(repo).startswith(f"<Repo '{path}' at 0x")

        # custom
        repo = config.add_repo(path, "fake")
        assert repo == config.repos["fake"]
        assert repo.id == "fake"
        assert str(repo) == "fake"
        assert repr(repo).startswith(f"<Repo 'fake' at 0x")

    def test_hash(self, repo):
        path = repo.path
        config = pkgcraft.config.load()
        repo1 = config.add_repo(path)
        repo2 = config.add_repo(path, "fake")
        s = {repo1, repo2}
        assert len(s) == 2
