from . cimport pkgcraft_c as C


ctypedef enum DepSetType:
    Atom,
    String,
    Uri


cdef class DepSet:
    cdef C.DepSet *_deps
    cdef DepSetType _type

    @staticmethod
    cdef DepSet from_ptr(C.DepSet *, DepSetType)


cdef class _DepSetFlatten:
    cdef C.DepSetFlatten *_iter
