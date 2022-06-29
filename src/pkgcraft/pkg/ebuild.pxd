from .. cimport pkgcraft_c as C
from .base cimport Pkg

cdef class EbuildPkg(Pkg):
    cdef C.EbuildPkg *_ebuild_pkg
    # cached fields
    cdef str _description
    cdef str _slot
