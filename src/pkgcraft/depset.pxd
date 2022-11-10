from . cimport pkgcraft_c as C


ctypedef enum DepSetType:
    DepSetAtom,
    DepSetString,
    DepSetUri


cdef class DepSet:
    cdef C.DepSet *_deps
    cdef DepSetType _type

    @staticmethod
    cdef DepSet from_ptr(C.DepSet *, DepSetType)


cdef class _DepSetFlatten:
    cdef C.DepSetFlatten *_iter
    cdef DepSetType _type

    @staticmethod
    cdef _DepSetFlatten create(DepSet)


cdef class Uri:
    cdef const C.Uri *_uri

    @staticmethod
    cdef Uri from_ptr(const C.Uri *)
