# SPDX-License-Identifier: MIT
# cython: language_level=3

# This file is auto-generated by cbindgen.

from libc.stdint cimport int8_t, int16_t, int32_t, int64_t, intptr_t
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t, uintptr_t
cdef extern from *:
    ctypedef bint bool
    ctypedef struct va_list

cdef extern from "pkgcraft.h":

    cdef struct Atom:
        pass

    cdef struct Version:
        pass

    Atom *pkgcraft_atom(char *atom, const char *eapi);

    Atom *pkgcraft_cpv(char *atom);

    int pkgcraft_atom_cmp(Atom *a1, Atom *a2);

    char *pkgcraft_atom_category(Atom *atom);

    char *pkgcraft_atom_package(Atom *atom);

    char *pkgcraft_atom_version(Atom *atom);

    char *pkgcraft_atom_revision(Atom *atom);

    char *pkgcraft_atom_slot(Atom *atom);

    char *pkgcraft_atom_subslot(Atom *atom);

    char *pkgcraft_atom_slot_op(Atom *atom);

    char **pkgcraft_atom_use_deps(Atom *atom);

    char *pkgcraft_atom_repo(Atom *atom);

    char *pkgcraft_atom_key(Atom *atom);

    char *pkgcraft_atom_cpv(Atom *atom);

    char *pkgcraft_atom_str(Atom *atom);

    void pkgcraft_atom_free(Atom *atom);

    uint64_t pkgcraft_atom_hash(Atom *atom);

    char *pkgcraft_last_error();

    void pkgcraft_str_free(char *s);

    void pkgcraft_str_array_free(char **array);

    char *pkgcraft_parse_atom(char *atom, const char *eapi);

    const char *pkgcraft_parse_category(const char *cstr);

    const char *pkgcraft_parse_package(const char *cstr);

    const char *pkgcraft_parse_version(const char *cstr);

    const char *pkgcraft_parse_repo(const char *cstr);

    const char *pkgcraft_parse_cpv(const char *cstr);

    Version *pkgcraft_version(const char *version);

    int pkgcraft_version_cmp(Version *v1, Version *v2);

    char *pkgcraft_version_revision(Version *version);

    char *pkgcraft_version_str(Version *version);

    void pkgcraft_version_free(Version *version);

    uint64_t pkgcraft_version_hash(Version *version);
