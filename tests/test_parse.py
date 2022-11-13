import pytest

from pkgcraft import parse
from pkgcraft.eapi import EAPIS
from pkgcraft.error import PkgcraftError


def test_atom():
    assert parse.atom('cat/pkg')
    assert parse.atom('=cat/pkg-1-r2:3/4[a,b,c]', EAPIS['8'])
    assert parse.atom('=cat/pkg-1-r2:3/4[a,b,c]', '8')

    # invalid
    for s in ('cat', '=cat/pkg'):
        with pytest.raises(PkgcraftError, match=f'invalid atom: {s}'):
            parse.atom(s)

def test_category():
    assert parse.category('cat')

    # invalid
    for s in ('cat egory', '-cat', 'cat@'):
        with pytest.raises(PkgcraftError, match=f'invalid category name: {s}'):
            parse.category(s)

def test_package():
    assert parse.package('pkg')

    # invalid
    for s in ('-pkg', 'pkg-1'):
        with pytest.raises(PkgcraftError, match=f'invalid package name: {s}'):
            parse.package(s)

def test_version():
    assert parse.version('1-r0')

    # invalid
    for s in ('-1', '1a1'):
        with pytest.raises(PkgcraftError, match=f'invalid version: {s}'):
            parse.version(s)

def test_repo():
    assert parse.repo('repo')

    # invalid
    for s in ('-repo', 'repo-1'):
        with pytest.raises(PkgcraftError, match=f'invalid repo name: {s}'):
            parse.repo(s)

def test_cpv():
    assert parse.cpv('cat/pkg-1')

    # invalid
    for s in ('cat', 'cat/pkg', '=cat/pkg-1'):
        with pytest.raises(PkgcraftError, match=f'invalid cpv: {s}'):
            parse.cpv(s)
