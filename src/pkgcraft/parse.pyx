from . cimport C
from .error import PkgcraftError


def category(s: str, raised=False):
    """Determine if a string is a valid category name."""
    valid = C.pkgcraft_parse_category(s.encode()) is not NULL
    if not valid and raised:
        raise PkgcraftError
    return valid


def package(s: str, raised=False):
    """Determine if a string is a valid package name."""
    valid = C.pkgcraft_parse_package(s.encode()) is not NULL
    if not valid and raised:
        raise PkgcraftError
    return valid


def repo(s: str, raised=False):
    """Determine if a string is a valid repo name."""
    valid = C.pkgcraft_parse_repo(s.encode()) is not NULL
    if not valid and raised:
        raise PkgcraftError
    return valid
