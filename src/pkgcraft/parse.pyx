from . cimport pkgcraft_c as C
from .error import PkgcraftError

def atom(s, eapi=None):
    """Parse an atom string.

    >>> from pkgcraft import parse
    >>> parse.atom('=cat/pkg-1')
    True
    """
    atom = (<str?>s).encode()
    cdef char *eapi_p = NULL
    if eapi is not None:
        eapi_bytes = (<str?>eapi).encode()
        eapi_p = eapi_bytes

    if C.pkgcraft_parse_atom(atom, eapi_p) is NULL:
        raise PkgcraftError
    return True

def category(s):
    """Parse an atom category string.

    >>> from pkgcraft import parse
    >>> parse.category('cat')
    True
    """
    cat = (<str?>s).encode()
    if not C.pkgcraft_parse_category(cat):
        raise PkgcraftError
    return True

def package(s):
    """Parse an atom package string.

    >>> from pkgcraft import parse
    >>> parse.package('pkg')
    True
    """
    pkg = (<str?>s).encode()
    if not C.pkgcraft_parse_package(pkg):
        raise PkgcraftError
    return True

def version(s):
    """Parse an atom version string.

    >>> from pkgcraft import parse
    >>> parse.version('1-r2')
    True
    """
    ver = (<str?>s).encode()
    if not C.pkgcraft_parse_version(ver):
        raise PkgcraftError
    return True

def repo(s):
    """Parse an atom repo string.

    >>> from pkgcraft import parse
    >>> parse.repo('repo')
    True
    """
    repo = (<str?>s).encode()
    if not C.pkgcraft_parse_repo(repo):
        raise PkgcraftError
    return True

def cpv(s):
    """Parse an atom cpv string.

    >>> from pkgcraft import parse
    >>> parse.cpv('cat/pkg-1')
    True
    """
    cpv = (<str?>s).encode()
    if not C.pkgcraft_parse_cpv(cpv):
        raise PkgcraftError
    return True
