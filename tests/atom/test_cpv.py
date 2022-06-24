import pytest

from pkgcraft.atom import Cpv, Version
from pkgcraft.error import PkgcraftError


class TestCpv:

    def test_new(self):
        a = Cpv('cat/pkg-1-r2')
        assert a.category == 'cat'
        assert a.package == 'pkg'
        assert a.version == Version('1-r2')
        assert a.revision == '2'
        assert a.key == 'cat/pkg'
        assert str(a) == 'cat/pkg-1-r2'
        assert repr(a).startswith("<Cpv 'cat/pkg-1-r2' at 0x")

    def test_invalid(self):
        for s in ('invalid', 'cat-1', 'cat/pkg', '=cat/pkg-1'):
            with pytest.raises(PkgcraftError, match=f'invalid cpv: "{s}"'):
                Cpv(s)
