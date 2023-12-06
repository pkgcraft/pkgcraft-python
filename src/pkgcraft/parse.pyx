from . cimport C

from .error import PkgcraftError


cpdef bint category(s: str, bint raised=False):
    """Determine if a string is a valid category name."""
    valid = C.pkgcraft_parse_category(s.encode()) is not NULL
    if not valid and raised:
        raise PkgcraftError
    return valid


cpdef bint package(s: str, bint raised=False):
    """Determine if a string is a valid package name."""
    valid = C.pkgcraft_parse_package(s.encode()) is not NULL
    if not valid and raised:
        raise PkgcraftError
    return valid


cpdef bint repo(s: str, bint raised=False):
    """Determine if a string is a valid repo name."""
    valid = C.pkgcraft_parse_repo(s.encode()) is not NULL
    if not valid and raised:
        raise PkgcraftError
    return valid


cpdef bint use_flag(s: str, bint raised=False):
    """Determine if a string is a valid USE flag name."""
    valid = C.pkgcraft_parse_use_flag(s.encode()) is not NULL
    if not valid and raised:
        raise PkgcraftError
    return valid
