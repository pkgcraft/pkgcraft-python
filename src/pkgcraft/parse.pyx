from . cimport C
from .error import PkgcraftError


def category(str s not None):
    """Parse a category string.

    >>> from pkgcraft import parse
    >>> parse.category('cat')
    True
    """
    if not C.pkgcraft_parse_category(s.encode()):
        raise PkgcraftError
    return True


def package(str s not None):
    """Parse a package name string.

    >>> from pkgcraft import parse
    >>> parse.package('pkg')
    True
    """
    if not C.pkgcraft_parse_package(s.encode()):
        raise PkgcraftError
    return True


def repo(str s not None):
    """Parse a repo string.

    >>> from pkgcraft import parse
    >>> parse.repo('repo')
    True
    """
    if not C.pkgcraft_parse_repo(s.encode()):
        raise PkgcraftError
    return True


def cpv(str s not None):
    """Parse a package CPV string.

    >>> from pkgcraft import parse
    >>> parse.cpv('cat/pkg-1')
    True
    """
    if not C.pkgcraft_parse_cpv(s.encode()):
        raise PkgcraftError
    return True
