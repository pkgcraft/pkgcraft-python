from .. cimport pkgcraft_c as C
from ..atom cimport Cpv
from ..error import PkgcraftError


cdef class EbuildPkg(Pkg):
    """Generic ebuild package."""
