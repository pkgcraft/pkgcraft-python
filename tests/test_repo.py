from pkgcraft import Repo


class TestRepo:

    def test_id(self, repo):
        # default
        test_repo = Repo(repo.path)
        assert test_repo.id == repo.path

        # custom
        test_repo = Repo(repo.path, "fake")
        assert test_repo.id == "fake"
