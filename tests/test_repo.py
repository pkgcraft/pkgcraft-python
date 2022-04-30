from pkgcraft import Repo


class TestRepo:

    def test_id(self, repo):
        path = repo.path

        # default
        repo = Repo(path)
        assert repo.id == path
        assert str(repo) == path
        assert repr(repo).startswith(f"<Repo '{path}: {path}' at 0x")

        # custom
        repo = Repo(path, "fake")
        assert repo.id == "fake"
        assert str(repo) == "fake"
        assert repr(repo).startswith(f"<Repo 'fake: {path}' at 0x")
