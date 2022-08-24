import pytest

from pkgcraft.eapi import get_eapi
from pkgcraft.error import PkgcraftError


class TestEapi:

    def test_valid(self):
        eapi = get_eapi('0')
        assert str(eapi) == '0'

    def test_unknown(self):
        with pytest.raises(PkgcraftError, match='unknown or invalid EAPI: unknown'):
            get_eapi('unknown')

    def test_invalid(self):
        with pytest.raises(PkgcraftError, match='unknown or invalid EAPI: +'):
            get_eapi('+')

    def test_has(self):
        eapi = get_eapi('1')
        assert not eapi.has('nonexistent_feature')
        assert eapi.has('slot_deps')

    def test_hash(self):
        s = {get_eapi('0'), get_eapi('1')}
        assert len(s) == 2
        s = {get_eapi('0'), get_eapi('0')}
        assert len(s) == 1
