import pytest

from pkgcraft import parse, PkgcraftError


def test_category():
    assert parse.category('cat') == 'cat'
    # invalid
    for s in ('cat egory', '-cat', 'cat@'):
        with pytest.raises(PkgcraftError, match=f'invalid category name: "{s}"'):
            parse.category(s)

def test_package():
    assert parse.package('pkg') == 'pkg'
    # invalid
    for s in ('-pkg', 'pkg-1'):
        with pytest.raises(PkgcraftError, match=f'invalid package name: "{s}"'):
            parse.package(s)

def test_version():
    v = parse.version('1-r0')
    assert v == '1-r0'

    # invalid
    for s in ('-1', '1a1'):
        with pytest.raises(PkgcraftError, match=f'invalid version: "{s}"'):
            parse.version(s)

def test_repo():
    assert parse.repo('repo') == 'repo'
    # invalid
    for s in ('-repo', 'repo-1'):
        with pytest.raises(PkgcraftError, match=f'invalid repo name: "{s}"'):
            parse.repo(s)

def test_cpv():
    a = parse.cpv('cat/pkg-1')
    assert a == 'cat/pkg-1'

    # invalid
    for s in ('cat', 'cat/pkg', '=cat/pkg-1'):
        with pytest.raises(PkgcraftError, match=f'invalid cpv: "{s}"'):
            parse.cpv(s)
