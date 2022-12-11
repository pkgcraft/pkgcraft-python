import pytest

from pkgcraft.atom import Cpv, Version
from pkgcraft.eapi import EAPI_LATEST


class BasePkgTests:

    def test_atom_base(self, repo):
        pkg = repo.create_pkg('cat/pkg-1')
        assert pkg.atom == Cpv('cat/pkg-1')

    def test_eapi_base(self, repo):
        pkg = repo.create_pkg('cat/pkg-1')
        assert pkg.eapi is EAPI_LATEST

    def test_repo(self, repo):
        pkg = repo.create_pkg('cat/pkg-1')
        assert pkg.repo == repo
        # repo attribute allows recursion
        assert pkg == next(iter(pkg.repo))

    def test_version_base(self, repo):
        pkg = repo.create_pkg('cat/pkg-1')
        assert pkg.version == Version('1')

    def test_cmp_base(self, repo):
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

    def test_str_base(self, repo):
        pkg = repo.create_pkg('cat/pkg-1')
        assert str(pkg) == 'cat/pkg-1::fake'

    def test_repr_base(self, repo):
        pkg = repo.create_pkg('cat/pkg-1')
        cls = pkg.__class__.__name__
        assert repr(pkg).startswith(f"<{cls} 'cat/pkg-1::fake' at 0x")

    def test_hash_base(self, repo):
        pkg1 = repo.create_pkg('cat/pkg-1')
        pkg2 = repo.create_pkg('cat/pkg-2')
        assert len({pkg1, pkg1}) == 1
        assert len({pkg1, pkg2}) == 2
