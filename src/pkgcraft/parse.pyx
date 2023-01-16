from . cimport pkgcraft_c as C
from .eapi cimport eapi_ptr_from_obj
from .error import PkgcraftError


def atom(str s not None, eapi=None):
    """Parse an atom string.

    >>> from pkgcraft import parse
    >>> parse.atom('=cat/pkg-1')
    True
    """
    eapi_ptr = eapi_ptr_from_obj(eapi) if eapi is not None else NULL
    if C.pkgcraft_parse_atom(s.encode(), eapi_ptr) is NULL:
        raise PkgcraftError
    return True


def category(str s not None):
    """Parse an atom category string.

    >>> from pkgcraft import parse
    >>> parse.category('cat')
    True
    """
    if not C.pkgcraft_parse_category(s.encode()):
        raise PkgcraftError
    return True


def package(str s not None):
    """Parse an atom package string.

    >>> from pkgcraft import parse
    >>> parse.package('pkg')
    True
    """
    if not C.pkgcraft_parse_package(s.encode()):
        raise PkgcraftError
    return True


def version(str s not None):
    """Parse an atom version string.

    >>> from pkgcraft import parse
    >>> parse.version('1-r2')
    True
    """
    if not C.pkgcraft_parse_version(s.encode()):
        raise PkgcraftError
    return True


def repo(str s not None):
    """Parse an atom repo string.

    >>> from pkgcraft import parse
    >>> parse.repo('repo')
    True
    """
    if not C.pkgcraft_parse_repo(s.encode()):
        raise PkgcraftError
    return True


def cpv(str s not None):
    """Parse an atom cpv string.

    >>> from pkgcraft import parse
    >>> parse.cpv('cat/pkg-1')
    True
    """
    if not C.pkgcraft_parse_cpv(s.encode()):
        raise PkgcraftError
    return True
