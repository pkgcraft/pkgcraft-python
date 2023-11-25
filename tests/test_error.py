import pytest

from pkgcraft.eapi import Eapi
from pkgcraft.error import InternalType, PkgcraftError


class TestPkgcraftError:
    def test_init(self):
        with pytest.raises(PkgcraftError, match="error message"):
            raise PkgcraftError("error message")

    def test_no_c_error(self):
        with pytest.raises(RuntimeError, match="no pkgcraft error occurred"):
            raise PkgcraftError


class TestInternalType:
    def test_class_init(self):
        with pytest.raises(InternalType):
            Eapi()
