from .. cimport pkgcraft_c as C
from . cimport Pkg

cdef class EbuildPkg(Pkg):
    cdef C.EbuildPkg *_ebuild_pkg
    # cached fields
    cdef str _description
    cdef str _slot
    cdef tuple _homepage
    cdef tuple _keywords
    cdef tuple _iuse
