import pytest

from pkgcraft.error import IndirectType, PkgcraftError
from pkgcraft.repo import Repo


class TestPkgcraftError:

    def test_new(self):
        with pytest.raises(PkgcraftError, match='error message'):
            raise PkgcraftError('error message')

    def test_no_c_error(self):
        with pytest.raises(RuntimeError, match='no pkgcraft-c error occurred'):
            raise PkgcraftError


class TestIndirectType:

    def test_class_init(self):
        with pytest.raises(IndirectType):
            Repo()
