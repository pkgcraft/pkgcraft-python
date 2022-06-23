from pkgcraft.atom import Cpv
from pkgcraft.config import Config


class TestRepo:

    def test_attrs(self, repo):
        path = repo.path
        config = Config()

        # default
        r = config.add_repo(path)
        assert r.id == path
        assert str(r) == path
        assert repr(r).startswith(f"<Repo '{path}' at 0x")

        # custom
        r = config.add_repo(path, "fake")
        assert r.id == "fake"
        assert str(r) == "fake"
        assert repr(r).startswith(f"<Repo 'fake' at 0x")

    def test_hash(self, repo):
        path = repo.path
        config = Config()
        r1 = config.add_repo(path)
        r2 = config.add_repo(path, "fake")
        s = {r1, r2}
        assert len(s) == 2

    def test_len(self, repo):
        path = repo.path
        config = Config()
        r = config.add_repo(path)

        # empty repo
        assert len(r) == 0

        # create ebuild
        repo.create_ebuild("cat/pkg-1")
        assert len(r) == 1

        # recreate ebuild
        repo.create_ebuild("cat/pkg-1")
        assert len(r) == 1

        # create new ebuild version
        repo.create_ebuild("cat/pkg-2")
        assert len(r) == 2

    def test_iter(self, repo):
        path = repo.path
        config = Config()
        r = config.add_repo(path)

        # empty repo
        assert not list(iter(r))

        # create ebuild
        repo.create_ebuild("cat/pkg-1")
        pkgs = list(iter(r))
        assert len(pkgs) == 1
        assert pkgs[0].atom == Cpv('cat/pkg-1')
