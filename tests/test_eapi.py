import pytest

from pkgcraft.eapi import get_eapi, Eapi, EAPIS, EAPI_LATEST, EAPIS_OFFICIAL
from pkgcraft.error import PkgcraftError


def test_globals():
    assert EAPIS['1'] is EAPIS_OFFICIAL['1']
    assert len(EAPIS) > len(EAPIS_OFFICIAL)
    assert EAPI_LATEST in EAPIS.values()


class TestEapi:

    def test_init(self):
        with pytest.raises(RuntimeError, match="doesn't support manual construction"):
            Eapi()

    def test_valid(self):
        eapi = get_eapi('0')
        assert str(eapi) == '0'
        assert repr(eapi).startswith(f"<Eapi '0' at 0x")

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

    def test_cmp(self):
        EAPI0 = EAPIS['0']
        EAPI1 = EAPIS['1']
        assert EAPI0 < EAPI1
        assert EAPI0 <= EAPI1
        assert EAPI1 <= EAPI1
        assert EAPI1 == EAPI1
        assert EAPI0 != EAPI1
        assert EAPI1 >= EAPI1
        assert EAPI1 >= EAPI0
        assert EAPI1 > EAPI0

    def test_hash(self):
        s = {get_eapi('0'), get_eapi('1')}
        assert len(s) == 2
        s = {get_eapi('0'), get_eapi('0')}
        assert len(s) == 1
