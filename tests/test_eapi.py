import pickle

import pytest

from pkgcraft.eapi import *

from .misc import OperatorMap


def test_globals():
    assert len(EAPIS) > len(EAPIS_OFFICIAL)
    # verify objects are shared between EAPIS_OFFICIAL and EAPIS
    for id, eapi in EAPIS_OFFICIAL.items():
        assert EAPIS[id] is eapi
    assert EAPIS[str(EAPI_LATEST_OFFICIAL)] is EAPI_LATEST_OFFICIAL
    assert EAPIS[str(EAPI_LATEST)] is EAPI_LATEST
    assert EAPI_LATEST_OFFICIAL is not EAPI_LATEST


class TestEapi:
    def test_has(self):
        assert not EAPI_LATEST_OFFICIAL.has("repo_ids")
        assert EAPI_LATEST.has("repo_ids")
        assert not EAPI_LATEST.has("nonexistent_feature")

        # invalid feature param type
        for obj in (object(), None):
            with pytest.raises(TypeError):
                EAPI_LATEST.has(obj)

    def test_dep_keys(self):
        assert "BDEPEND" in EAPI_LATEST.dep_keys
        assert "NONEXISTENT" not in EAPI_LATEST.dep_keys

    def test_metadata_keys(self):
        assert "SLOT" in EAPI_LATEST.metadata_keys
        assert "NONEXISTENT" not in EAPI_LATEST.metadata_keys

    def test_methods(self):
        assert str(EAPI8) == "8"
        assert repr(EAPI8).startswith("<Eapi '8' at 0x")

    def test_cmp(self):
        assert EAPI7 < EAPI8
        assert EAPI8 <= EAPI8
        assert EAPI8 <= EAPI8
        assert EAPI8 == EAPI8
        assert EAPI7 != EAPI8
        assert EAPI8 >= EAPI7
        assert EAPI8 >= EAPI7
        assert EAPI8 > EAPI7

        # verify incompatible type comparisons
        obj = EAPI_LATEST
        for op, op_func in OperatorMap.items():
            if op == "==":
                assert not op_func(obj, None)
            elif op == "!=":
                assert op_func(obj, None)
            else:
                with pytest.raises(TypeError):
                    op_func(obj, None)

    def test_hash(self):
        s = {EAPI7, EAPI8}
        assert len(s) == 2
        s = {EAPI8, EAPI8}
        assert len(s) == 1

    def test_from_obj(self):
        assert Eapi.from_obj(EAPI8) is EAPI8
        assert Eapi.from_obj("8") is EAPI8

        # unknown EAPI
        with pytest.raises(ValueError):
            assert Eapi.from_obj("unknown")

        # invalid type
        with pytest.raises(TypeError):
            assert Eapi.from_obj(object())

    def test_eapi_pickle(self):
        e1 = EAPI8
        e2 = pickle.loads(pickle.dumps(e1))
        assert e1 is e2
