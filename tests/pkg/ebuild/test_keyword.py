import re

import pytest

from pkgcraft.error import PkgcraftError
from pkgcraft.pkg import *


class TestKeyword:
    def test_creation(self):
        # valid
        for s, arch, status in (
            ("arch", "arch", KeywordStatus.Stable),
            ("-arch", "arch", KeywordStatus.Disabled),
            ("~arch", "arch", KeywordStatus.Unstable),
            ("-*", "*", KeywordStatus.Disabled),
            ("_", "_", KeywordStatus.Stable),
            ("-_", "_", KeywordStatus.Disabled),
            ("~_", "_", KeywordStatus.Unstable),
        ):
            kw = Keyword(s)
            assert kw.arch == arch
            assert kw.status == status
            assert str(kw) == s
            assert s in repr(kw)

        # invalid
        for s in ("", "-", "-@", "--arch", "-~arch", "~-arch"):
            with pytest.raises(PkgcraftError, match=f"invalid keyword: {re.escape(s)}"):
                Keyword(s)

    def test_cmp(self):
        for s1, s2 in (
            ("-arch", "~arch"),
            ("~arch", "arch"),
            ("arch1-plat1", "arch2-plat2"),
            ("arch2-plat1", "arch1-plat2"),
            ("zarch", "arch-linux"),
        ):
            kw1 = Keyword(s1)
            kw2 = Keyword(s2)
            obj = object()

            assert kw1 < kw2
            with pytest.raises(TypeError):
                assert kw1 < obj

            assert kw1 <= kw2
            assert kw2 <= kw2
            with pytest.raises(TypeError):
                assert kw1 <= obj

            assert kw1 == kw1
            assert not kw1 == obj

            assert kw1 != kw2
            assert kw1 != obj

            assert kw2 >= kw1
            assert kw2 >= kw2
            with pytest.raises(TypeError):
                assert kw2 >= obj

            assert kw2 > kw1
            with pytest.raises(TypeError):
                assert kw2 > obj

    def test_eq_and_hash(self):
        # not equal
        kw1 = Keyword("~arch")
        kw2 = Keyword("arch")
        assert kw1 != kw2
        assert len({kw1, kw2}) == 2

        # equal
        kw1 = Keyword("-arch")
        kw2 = Keyword("-arch")
        assert kw1 == kw2
        assert len({kw1, kw2}) == 1
