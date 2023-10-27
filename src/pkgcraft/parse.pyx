from . cimport C
from .error import PkgcraftError


def category(str s not None):
    """Determine if a string is a valid category name."""
    if not C.pkgcraft_parse_category(s.encode()):
        raise PkgcraftError
    return True


def package(str s not None):
    """Determine if a string is a valid package name."""
    if not C.pkgcraft_parse_package(s.encode()):
        raise PkgcraftError
    return True


def repo(str s not None):
    """Determine if a string is a valid repo name."""
    if not C.pkgcraft_parse_repo(s.encode()):
        raise PkgcraftError
    return True
