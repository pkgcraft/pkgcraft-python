from . cimport pkgcraft_c as C


ctypedef enum DepSetType:
    DepSetAtom,
    DepSetString,
    DepSetUri


cdef class DepRestrict:
    cdef C.DepRestrict *_restrict
    cdef DepSetType _type

    @staticmethod
    cdef DepRestrict from_ptr(C.DepRestrict *, DepSetType)


cdef class DepSet:
    cdef C.DepSet *_deps
    cdef DepSetType _type
    cdef C.DepSetIter *_iter

    @staticmethod
    cdef DepSet from_ptr(C.DepSet *, DepSetType)


cdef class _DepSetFlatten:
    cdef C.DepSetFlatten *_iter
    cdef DepSetType _type

    @staticmethod
    cdef _DepSetFlatten from_deprestrict(DepRestrict)
    @staticmethod
    cdef _DepSetFlatten from_depset(DepSet)


cdef class Uri:
    cdef const C.Uri *_uri
    # cached fields
    cdef str _uri_str

    @staticmethod
    cdef Uri from_ptr(const C.Uri *)
