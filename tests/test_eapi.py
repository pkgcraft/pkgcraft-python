import pickle

import pytest

from pkgcraft.eapi import EAPI0, EAPI1, EAPI_LATEST, EAPIS, EAPIS_OFFICIAL, eapi_from_obj


def test_globals():
    assert len(EAPIS) > len(EAPIS_OFFICIAL)
    # verify objects are shared between EAPIS_OFFICIAL and EAPIS
    for (id, eapi) in EAPIS_OFFICIAL.items():
        assert EAPIS[id] is eapi
    assert EAPIS[str(EAPI_LATEST)] is EAPI_LATEST


def test_eapi_from_obj():
    assert eapi_from_obj(EAPI0) is EAPI0
    assert eapi_from_obj("0") is EAPI0

    # unknown EAPI
    with pytest.raises(ValueError):
        assert eapi_from_obj("unknown")

    # invalid type
    with pytest.raises(TypeError):
        assert eapi_from_obj(object())


class TestEapi:
    def test_has(self):
        assert not EAPI1.has("nonexistent_feature")
        assert EAPI1.has("slot_deps")

        # invalid feature param type
        for obj in (object(), None):
            with pytest.raises(TypeError):
                EAPI1.has(obj)

    def test_dep_keys(self):
        assert "DEPEND" in EAPI0.dep_keys
        assert "BDEPEND" not in EAPI0.dep_keys
        assert "BDEPEND" in EAPI_LATEST.dep_keys

    def test_metadata_keys(self):
        assert "SLOT" in EAPI0.metadata_keys
        assert "REQUIRED_USE" not in EAPI0.metadata_keys
        assert "REQUIRED_USE" in EAPI_LATEST.metadata_keys

    def test_methods(self):
        assert str(EAPI0) == "0"
        assert repr(EAPI0).startswith(f"<Eapi '0' at 0x")

    def test_cmp(self):
        assert EAPI0 < EAPI1
        assert EAPI0 <= EAPI1
        assert EAPI1 <= EAPI1
        assert EAPI1 == EAPI1
        assert EAPI0 != EAPI1
        assert EAPI1 >= EAPI1
        assert EAPI1 >= EAPI0
        assert EAPI1 > EAPI0

    def test_hash(self):
        s = {EAPI0, EAPI1}
        assert len(s) == 2
        s = {EAPI0, EAPI0}
        assert len(s) == 1

    def test_eapi_pickle(self):
        e1 = EAPI0
        e2 = pickle.loads(pickle.dumps(e1))
        assert e1 is e2
