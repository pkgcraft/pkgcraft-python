from . cimport pkgcraft_c as C
from .error import PkgcraftError

def atom(atom not None, eapi=None):
    """Parse an atom string.

    >>> from pkgcraft import parse
    >>> parse.atom('=cat/pkg-1')
    True
    """
    cdef char *eapi_p = NULL
    if eapi is not None:
        eapi_bytes = str(eapi).encode()
        eapi_p = eapi_bytes

    if C.pkgcraft_parse_atom(str(atom).encode(), eapi_p) is NULL:
        raise PkgcraftError
    return True

def category(s not None):
    """Parse an atom category string.

    >>> from pkgcraft import parse
    >>> parse.category('cat')
    True
    """
    if not C.pkgcraft_parse_category(str(s).encode()):
        raise PkgcraftError
    return True

def package(s not None):
    """Parse an atom package string.

    >>> from pkgcraft import parse
    >>> parse.package('pkg')
    True
    """
    if not C.pkgcraft_parse_package(str(s).encode()):
        raise PkgcraftError
    return True

def version(s not None):
    """Parse an atom version string.

    >>> from pkgcraft import parse
    >>> parse.version('1-r2')
    True
    """
    if not C.pkgcraft_parse_version(str(s).encode()):
        raise PkgcraftError
    return True

def repo(s not None):
    """Parse an atom repo string.

    >>> from pkgcraft import parse
    >>> parse.repo('repo')
    True
    """
    if not C.pkgcraft_parse_repo(str(s).encode()):
        raise PkgcraftError
    return True

def cpv(s not None):
    """Parse an atom cpv string.

    >>> from pkgcraft import parse
    >>> parse.cpv('cat/pkg-1')
    True
    """
    if not C.pkgcraft_parse_cpv(str(s).encode()):
        raise PkgcraftError
    return True
