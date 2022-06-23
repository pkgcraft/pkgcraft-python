# SPDX-License-Identifier: MIT
# cython: language_level=3

from . cimport pkgcraft_c as C
from .error import PkgcraftError

def atom(str atom not None, str eapi=None):
    """Parse an atom string.

    valid
    >>> from pkgcraft import parse
    >>> parse.atom('=cat/pkg-1')
    True

    invalid
    >>> parse.atom('cat/pkg-1')
    Traceback (most recent call last):
        ...
    pkgcraft.error.PkgcraftError: parsing failure: invalid atom: "cat/pkg-1"
      |
    1 | cat/pkg-1
      |        ^ Expected: EOF
      |
    """
    atom_bytes = atom.encode()
    cdef char* atom_p = atom_bytes

    cdef char* eapi_p = NULL
    if eapi is not None:
        eapi_bytes = eapi.encode()
        eapi_p = eapi_bytes

    if C.pkgcraft_parse_atom(atom_p, eapi_p) is NULL:
        raise PkgcraftError
    return True

def category(str s not None):
    """Parse an atom category string.

    valid
    >>> from pkgcraft import parse
    >>> parse.category('cat')
    True

    invalid
    >>> parse.category('cat@')
    Traceback (most recent call last):
        ...
    pkgcraft.error.PkgcraftError: parsing failure: invalid category name: "cat@"
      |
    1 | cat@
      |    ^ Expected: EOF
      |
    """
    if not C.pkgcraft_parse_category(s.encode()):
        raise PkgcraftError
    return True

def package(str s not None):
    """Parse an atom package string.

    valid
    >>> from pkgcraft import parse
    >>> parse.package('pkg')
    True

    invalid
    >>> parse.package('pkg@')
    Traceback (most recent call last):
        ...
    pkgcraft.error.PkgcraftError: parsing failure: invalid package name: "pkg@"
      |
    1 | pkg@
      |    ^ Expected: EOF
      |
    """
    if not C.pkgcraft_parse_package(s.encode()):
        raise PkgcraftError
    return True

def version(str s not None):
    """Parse an atom version string.

    valid
    >>> from pkgcraft import parse
    >>> parse.version('1-r2')
    True

    invalid
    >>> parse.version('1-r')
    Traceback (most recent call last):
        ...
    pkgcraft.error.PkgcraftError: parsing failure: invalid version: "1-r"
      |
    1 | 1-r
      |    ^ Expected: revision
      |
    """
    if not C.pkgcraft_parse_version(s.encode()):
        raise PkgcraftError
    return True

def repo(str s not None):
    """Parse an atom repo string.

    valid
    >>> from pkgcraft import parse
    >>> parse.repo('repo')
    True

    invalid
    >>> parse.repo('repo#')
    Traceback (most recent call last):
        ...
    pkgcraft.error.PkgcraftError: parsing failure: invalid repo name: "repo#"
      |
    1 | repo#
      |     ^ Expected: EOF
      |
    """
    if not C.pkgcraft_parse_repo(s.encode()):
        raise PkgcraftError
    return True

def cpv(str s not None):
    """Parse an atom cpv string.

    valid
    >>> from pkgcraft import parse
    >>> parse.cpv('cat/pkg-1')
    True

    invalid
    >>> parse.cpv('cat/pkg')
    Traceback (most recent call last):
        ...
    pkgcraft.error.PkgcraftError: parsing failure: invalid cpv: "cat/pkg"
      |
    1 | cat/pkg
      |        ^ Expected: "-"
      |
    """
    if not C.pkgcraft_parse_cpv(s.encode()):
        raise PkgcraftError
    return True
