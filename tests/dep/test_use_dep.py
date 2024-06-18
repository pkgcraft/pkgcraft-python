import re

import pytest

from pkgcraft.dep import *
from pkgcraft.error import PkgcraftError


class TestUseDep:
    def test_creation(self):
        # valid
        for d, default in (
            ("", None),
            ("(+)", UseDepDefault.Enabled),
            ("(-)", UseDepDefault.Disabled),
        ):
            for s, kind in (
                (f"u{d}", UseDepKind.Enabled),
                (f"-u{d}", UseDepKind.Disabled),
                (f"u{d}=", UseDepKind.Equal),
                (f"!u{d}=", UseDepKind.NotEqual),
                (f"u{d}?", UseDepKind.EnabledConditional),
                (f"!u{d}?", UseDepKind.DisabledConditional),
            ):
                use = UseDep(s)
                assert use.kind == kind
                assert use.flag == "u"
                assert use.default == default
                # verify the internal field is hidden from native python
                assert getattr(use, "default_", None) is None
                assert str(use) == s
                assert s in repr(use)

        # invalid
        for s in ("u?(+)", "!-u"):
            with pytest.raises(PkgcraftError, match=f"invalid use dep: {re.escape(s)}"):
                UseDep(s)

    def test_cmp(self):
        for s1, s2 in (("a", "b"), ("u", "-u"), ("u(+)", "u(-)"), ("u?", "!u?")):
            use1 = UseDep(s1)
            use2 = UseDep(s2)
            obj = object()

            assert use1 < use2
            with pytest.raises(TypeError):
                assert use1 < obj

            assert use1 <= use2
            assert use2 <= use2
            with pytest.raises(TypeError):
                assert use1 <= obj

            assert use1 == use1
            assert not use1 == obj

            assert use1 != use2
            assert use1 != obj

            assert use2 >= use1
            assert use2 >= use2
            with pytest.raises(TypeError):
                assert use2 >= obj

            assert use2 > use1
            with pytest.raises(TypeError):
                assert use2 > obj

    def test_eq_and_hash(self):
        # not equal
        u1 = UseDep("a")
        u2 = UseDep("b")
        assert u1 != u2
        assert len({u1, u2}) == 2

        # equal
        u1 = UseDep("!u(-)?")
        u2 = UseDep("!u(-)?")
        assert u1 == u2
        assert len({u1, u2}) == 1

        # set membership
        u = UseDep("c(+)?")
        dep = Dep("!!>=cat/pkg-1-r2:0/2=::repo[a,-b,c(+)?]")
        assert u in dep.use_deps

        # other types
        for obj in [None, "a/b", object()]:
            assert u != obj
            assert not u == obj
