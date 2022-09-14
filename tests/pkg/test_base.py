import pytest

from pkgcraft.pkg import Pkg


class TestPkg:

    def test_init(self):
        with pytest.raises(RuntimeError, match="doesn't support manual construction"):
            Pkg()

    def test_cmp(self, repo):
        pkg1 = repo.create_pkg('cat/pkg-1')
        pkg2 = repo.create_pkg('cat/pkg-2')
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
        pkg1 = repo.create_pkg('cat/pkg-1')
        pkg2 = repo.create_pkg('cat/pkg-2')
        assert len({pkg1, pkg1}) == 1
        assert len({pkg1, pkg2}) == 2
