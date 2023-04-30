from . cimport C
from .eapi cimport Eapi
from .error import PkgcraftError


def dep(str s not None, eapi=None):
    """Parse a package dependency string.

    >>> from pkgcraft import parse
    >>> parse.dep('=cat/pkg-1')
    True
    """
    cdef const C.Eapi *eapi_ptr = NULL
    if eapi is not None:
        eapi_ptr = Eapi._from_obj(eapi).ptr

    if C.pkgcraft_parse_dep(s.encode(), eapi_ptr) is NULL:
        raise PkgcraftError
    return True


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


def version(str s not None):
    """Parse a version string.

    >>> from pkgcraft import parse
    >>> parse.version('1-r2')
    True
    """
    if not C.pkgcraft_parse_version(s.encode()):
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
