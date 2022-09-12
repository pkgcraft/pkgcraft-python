from . cimport pkgcraft_c as C

cdef C.Restrict *obj_to_restrict(object obj) except NULL
cdef C.Restrict *str_to_restrict(str s) except NULL

cdef class Restrict:
    cdef C.Restrict *_restrict
