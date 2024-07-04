from ...dep cimport DependencySet
from ...types cimport OrderedFrozenSet
from .. cimport Pkg


cdef class EbuildPkg(Pkg):
    # cached fields
    cdef str _description
    cdef str _slot
    cdef str _subslot
    cdef DependencySet _depend
    cdef DependencySet _bdepend
    cdef DependencySet _idepend
    cdef DependencySet _pdepend
    cdef DependencySet _rdepend
    cdef DependencySet _license
    cdef DependencySet _properties
    cdef DependencySet _required_use
    cdef DependencySet _restrict
    cdef DependencySet _src_uri
    cdef OrderedFrozenSet _defined_phases
    cdef OrderedFrozenSet _homepage
    cdef OrderedFrozenSet _keywords
    cdef OrderedFrozenSet _inherit
    cdef OrderedFrozenSet _inherited
    cdef OrderedFrozenSet _iuse
    cdef OrderedFrozenSet _maintainers
    cdef object _upstream


cdef class ConfiguredPkg(EbuildPkg):
    pass
