import pytest

from pkgcraft.eapi import EAPI_LATEST
from pkgcraft.error import IndirectInit
from pkgcraft.pkg import FakePkg
from pkgcraft.repo import FakeRepo
from pkgcraft.atom import Cpv, Version


@pytest.fixture
def repo():
    return FakeRepo('fake', 0, ['cat/pkg-1'])


@pytest.fixture
def pkg(repo):
    return next(iter(repo))


class TestFakePkg:

    def test_init(self):
        with pytest.raises(IndirectInit):
            FakePkg()

    def test_repr(self, pkg):
        assert repr(pkg).startswith(f"<FakePkg 'cat/pkg-1::fake' at 0x")

    def test_atom(self, pkg):
        assert pkg.atom == Cpv('cat/pkg-1')

    def test_repo(self, repo, pkg):
        assert pkg.repo == repo
        # repo attribute allows recursion
        assert pkg == next(iter(pkg.repo))

    def test_eapi(self, pkg):
        assert pkg.eapi is EAPI_LATEST

    def test_version(self, pkg):
        assert pkg.version == Version('1')
