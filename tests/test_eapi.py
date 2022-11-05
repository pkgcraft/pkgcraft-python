import pytest

from pkgcraft.eapi import Eapi, EAPIS, EAPI_LATEST, EAPIS_OFFICIAL
from pkgcraft.error import IndirectInit, PkgcraftError


def test_globals():
    assert len(EAPIS) > len(EAPIS_OFFICIAL)
    # verify objects are shared between EAPIS_OFFICIAL and EAPIS
    for (id, eapi) in EAPIS_OFFICIAL.items():
        assert EAPIS[id] is eapi
    assert EAPIS[str(EAPI_LATEST)] is EAPI_LATEST


class TestEapi:

    def test_init(self):
        with pytest.raises(IndirectInit):
            Eapi()

    def test_valid(self):
        eapi = Eapi.get('0')
        assert str(eapi) == '0'
        assert repr(eapi).startswith(f"<Eapi '0' at 0x")

    def test_unknown(self):
        with pytest.raises(PkgcraftError, match='unknown or invalid EAPI: unknown'):
            Eapi.get('unknown')

    def test_invalid(self):
        with pytest.raises(PkgcraftError, match='unknown or invalid EAPI: +'):
            Eapi.get('+')

    def test_has(self):
        eapi = Eapi.get('1')
        assert not eapi.has('nonexistent_feature')
        assert eapi.has('slot_deps')

        # invalid feature param type
        for obj in (object(), None):
            with pytest.raises(TypeError):
                eapi.has(obj)

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
        s = {Eapi.get('0'), Eapi.get('1')}
        assert len(s) == 2
        s = {Eapi.get('0'), Eapi.get('0')}
        assert len(s) == 1
