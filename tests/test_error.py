import pytest

from pkgcraft.eapi import Eapi
from pkgcraft.error import IndirectType, PkgcraftError


class TestPkgcraftError:
    def test_init(self):
        with pytest.raises(PkgcraftError, match="error message"):
            raise PkgcraftError("error message")

    def test_no_c_error(self):
        with pytest.raises(RuntimeError, match="no pkgcraft error occurred"):
            raise PkgcraftError

    def test_subclass_registry(self):
        with pytest.raises(RuntimeError, match="error kind 0 already registered to PkgcraftError"):

            class _NewError(PkgcraftError):
                kinds = (0,)


class TestIndirectType:
    def test_class_init(self):
        with pytest.raises(IndirectType):
            Eapi()
        with pytest.raises(IndirectType):
            Eapi("8")
        with pytest.raises(IndirectType):
            Eapi(eapi="8")
