import pickle

import pytest

from pkgcraft.eapi import *
from pkgcraft.error import PkgcraftError

from .misc import OperatorMap

EAPI_PREV_OFFICIAL = list(EAPIS_OFFICIAL.values())[-2]


def test_globals():
    assert len(EAPIS) > len(EAPIS_OFFICIAL)
    # verify objects are shared between EAPI globals
    for id, eapi in EAPIS_OFFICIAL.items():
        assert EAPIS[id] is eapi
        # official EAPIs have their own globals
        globals()[f"EAPI{id}"] is eapi
    assert EAPIS[str(EAPI_LATEST_OFFICIAL)] is EAPI_LATEST_OFFICIAL
    assert EAPIS[str(EAPI_LATEST)] is EAPI_LATEST
    assert EAPI_LATEST_OFFICIAL is not EAPI_LATEST


class TestEapi:
    def test_parse(self):
        assert Eapi.parse("01")
        for s in ("@1", "-1", ".1"):
            assert not Eapi.parse(s)
            with pytest.raises(PkgcraftError, match=f'invalid EAPI: "{s}"'):
                Eapi.parse(s, raised=True)

    def test_has(self):
        assert not EAPI_LATEST_OFFICIAL.has("RepoIds")
        assert EAPI_LATEST.has("RepoIds")
        assert not EAPI_LATEST.has("Nonexistent")

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
        s = str(EAPI_LATEST_OFFICIAL)
        assert f"Eapi '{s}' at 0x" in repr(EAPI_LATEST_OFFICIAL)

    def test_cmp(self):
        assert EAPI_PREV_OFFICIAL < EAPI_LATEST_OFFICIAL
        assert EAPI_PREV_OFFICIAL <= EAPI_LATEST_OFFICIAL
        assert EAPI_LATEST_OFFICIAL <= EAPI_LATEST_OFFICIAL
        assert EAPI_LATEST_OFFICIAL == EAPI_LATEST_OFFICIAL
        assert EAPI_PREV_OFFICIAL != EAPI_LATEST_OFFICIAL
        assert EAPI_LATEST_OFFICIAL >= EAPI_LATEST_OFFICIAL
        assert EAPI_LATEST_OFFICIAL >= EAPI_PREV_OFFICIAL
        assert EAPI_LATEST_OFFICIAL > EAPI_PREV_OFFICIAL

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
        s = {EAPI_PREV_OFFICIAL, EAPI_LATEST_OFFICIAL}
        assert len(s) == 2
        s = {EAPI_LATEST_OFFICIAL, EAPI_LATEST_OFFICIAL}
        assert len(s) == 1

    def test_from_obj(self):
        assert Eapi.from_obj(EAPI_LATEST_OFFICIAL) is EAPI_LATEST_OFFICIAL
        assert Eapi.from_obj(str(EAPI_LATEST_OFFICIAL)) is EAPI_LATEST_OFFICIAL

        # unknown EAPI
        with pytest.raises(ValueError):
            assert Eapi.from_obj("unknown")

        # invalid type
        with pytest.raises(TypeError):
            assert Eapi.from_obj(object())

    def test_eapi_pickle(self):
        eapi = pickle.loads(pickle.dumps(EAPI_LATEST_OFFICIAL))
        assert eapi is EAPI_LATEST_OFFICIAL
