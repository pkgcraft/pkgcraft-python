import pytest

from pkgcraft.atom import Cpv
from pkgcraft.repo import FakeRepo


class TestFakeRepo:

    def test_init(self, tmp_path):
        # empty file
        path = tmp_path / 'atoms'
        path.touch()
        r = FakeRepo(path)
        assert len(r) == 0

        # single pkg file
        path.write_text('cat/pkg-1')
        r = FakeRepo(path)
        assert len(r) == 1
        assert Cpv('cat/pkg-1') in r

        # multiple pkgs file with invalid cpv
        path.write_text('a/b-1\nc/d-2\n=cat/pkg-1')
        r = FakeRepo(path)
        assert len(r) == 2
        assert Cpv('a/b-1') in r
        assert Cpv('c/d-2') in r

        # empty iterable
        r = FakeRepo([], id='fake')
        assert len(r) == 0

        # single pkg iterable
        r = FakeRepo(['cat/pkg-1'], id='fake')
        assert len(r) == 1
        assert Cpv('cat/pkg-1') in r

        # multiple pkgs iterable with invalid cpv
        r = FakeRepo(['a/b-1', 'c/d-2', '=cat/pkg-1'], id='fake')
        assert len(r) == 2
        assert Cpv('a/b-1') in r
        assert Cpv('c/d-2') in r
