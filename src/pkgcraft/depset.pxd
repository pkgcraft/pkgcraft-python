from . cimport pkgcraft_c as C


cdef class DepSetAtom:
    cdef const C.DepSetAtom *_deps

    @staticmethod
    cdef DepSetAtom from_ptr(const C.DepSetAtom *)


cdef class DepSetString:
    cdef const C.DepSetString *_deps

    @staticmethod
    cdef DepSetString from_ptr(const C.DepSetString *)


cdef class DepSetUri:
    cdef const C.DepSetUri *_deps

    @staticmethod
    cdef DepSetUri from_ptr(const C.DepSetUri *)
