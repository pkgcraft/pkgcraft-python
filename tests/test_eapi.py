import pytest

from pkgcraft.eapi import Eapi
from pkgcraft.error import PkgcraftError


class TestEapi:

    def test_valid(self):
        eapi = Eapi('0')
        assert str(eapi) == '0'

    def test_unknown(self):
        with pytest.raises(PkgcraftError, match='unknown EAPI: unknown'):
            Eapi('unknown')

    def test_invalid(self):
        with pytest.raises(PkgcraftError, match='invalid EAPI: +'):
            Eapi('+')

    def test_has(self):
        eapi = Eapi('1')
        assert not eapi.has('nonexistent_feature')
        assert eapi.has('slot_deps')
