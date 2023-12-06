import pytest

from pkgcraft import parse
from pkgcraft.error import PkgcraftError


def test_category():
    assert parse.category("cat")

    # invalid
    for s in ("cat egory", "-cat", "cat@"):
        assert not parse.category(s)
        with pytest.raises(PkgcraftError, match=f"invalid category name: {s}"):
            parse.category(s, raised=True)


def test_package():
    assert parse.package("pkg")

    # invalid
    for s in ("-pkg", "pkg-1"):
        assert not parse.package(s)
        with pytest.raises(PkgcraftError, match=f"invalid package name: {s}"):
            parse.package(s, raised=True)


def test_repo():
    assert parse.repo("repo")

    # invalid
    for s in ("-repo", "repo-1"):
        assert not parse.repo(s)
        with pytest.raises(PkgcraftError, match=f"invalid repo name: {s}"):
            parse.repo(s, raised=True)


def test_use_flag():
    assert parse.use_flag("use")

    # invalid
    for s in ("use flag", "-use", "@use"):
        assert not parse.use_flag(s)
        with pytest.raises(PkgcraftError, match=f"invalid USE flag: {s}"):
            parse.use_flag(s, raised=True)
