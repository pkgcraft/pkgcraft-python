import pytest

from pkgcraft.config import Config
from pkgcraft.pkg import Pkg


class TestPkg:

    def test_init(self):
        with pytest.raises(RuntimeError, match="doesn't support manual construction"):
            Pkg()

    def test_cmp(self, repo):
        path = repo.path
        config = Config()
        r = config.add_repo_path(path)
        repo.create_ebuild('cat/pkg-1')
        repo.create_ebuild('cat/pkg-2')
        i = iter(r)
        pkg1 = next(i)
        pkg2 = next(i)
        assert pkg1 == pkg1
        assert pkg2 == pkg2
        assert pkg1 < pkg2 
        assert pkg1 <= pkg2
        assert pkg2 <= pkg2
        assert pkg1 != pkg2
        assert pkg2 >= pkg2
        assert pkg2 >= pkg1
        assert pkg2 > pkg1

    def test_hash(self, repo):
        path = repo.path
        config = Config()
        r = config.add_repo_path(path)
        repo.create_ebuild('cat/pkg-1')
        repo.create_ebuild('cat/pkg-2')
        i = iter(r)
        pkg1 = next(i)
        pkg2 = next(i)
        assert len({pkg1, pkg1}) == 1
        assert len({pkg1, pkg2}) == 2
