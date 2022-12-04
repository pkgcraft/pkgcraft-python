import pytest

from pkgcraft.error import IndirectInit
from pkgcraft.pkg import Pkg


class TestPkg:

    def test_init(self):
        with pytest.raises(IndirectInit):
            Pkg()

    def test_cmp(self, ebuild_repo):
        pkg1 = ebuild_repo.create_pkg('cat/pkg-1')
        pkg2 = ebuild_repo.create_pkg('cat/pkg-2')
        assert pkg1 == pkg1
        assert pkg2 == pkg2
        assert pkg1 < pkg2 
        assert pkg1 <= pkg2
        assert pkg2 <= pkg2
        assert pkg1 != pkg2
        assert pkg2 >= pkg2
        assert pkg2 >= pkg1
        assert pkg2 > pkg1

    def test_hash(self, ebuild_repo):
        pkg1 = ebuild_repo.create_pkg('cat/pkg-1')
        pkg2 = ebuild_repo.create_pkg('cat/pkg-2')
        assert len({pkg1, pkg1}) == 1
        assert len({pkg1, pkg2}) == 2
