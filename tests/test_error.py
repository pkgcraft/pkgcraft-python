import pytest

from pkgcraft.eapi import Eapi
from pkgcraft.error import IndirectInit, PkgcraftError


class TestPkgcraftError:

    def test_new(self):
        with pytest.raises(PkgcraftError, match='error message'):
            raise PkgcraftError('error message')

    def test_no_c_error(self):
        with pytest.raises(RuntimeError, match='no pkgcraft-c error occurred'):
            raise PkgcraftError


class TestIndirectInit:

    def test_class_init(self):
        with pytest.raises(IndirectInit):
            Eapi()
