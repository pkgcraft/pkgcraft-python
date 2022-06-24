# This file is auto-generated by cbindgen.

from libc.stdint cimport int8_t, int16_t, int32_t, int64_t, intptr_t
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t, uintptr_t
cdef extern from *:
    ctypedef bint bool
    ctypedef struct va_list

include "pkgcraft.pxi"

cdef extern from "pkgcraft.h":

    # Opaque wrapper for Atom objects.
    cdef struct Atom:
        pass

    # Opaque wrapper for Config objects.
    cdef struct Config:
        pass

    # Opaque wrapper for Pkg objects.
    cdef struct Pkg:
        pass

    # Opaque wrapper for PkgIter objects.
    cdef struct PkgIter:
        pass

    # Opaque wrapper for Repo objects.
    cdef struct Repo:
        pass

    # Opaque wrapper for Version objects.
    cdef struct Version:
        pass

    # Wrapper for configured repos.
    cdef struct RepoConfig:
        char *id;
        const Repo *repo;

    # Parse a string into an atom using a specific EAPI. Pass NULL for the eapi argument in
    # order to parse using the latest EAPI with extensions (e.g. support for repo deps).
    #
    # Returns NULL on error.
    #
    # # Safety
    # The atom argument should be a UTF-8 string while eapi can be a string or may be
    # NULL to use the default EAPI.
    Atom *pkgcraft_atom(char *atom, const char *eapi);

    # Return a given atom's blocker status, e.g. the atom "!cat/pkg" has a weak blocker.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    Blocker pkgcraft_atom_blocker(Atom *atom);

    # Return a given atom's category, e.g. the atom "=cat/pkg-1-r2" has a category of "cat".
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_category(Atom *atom);

    # Compare two atoms returning -1, 0, or 1 if the first atom is less than, equal to, or greater
    # than the second atom, respectively.
    #
    # # Safety
    # The arguments must be non-null Atom pointers.
    int pkgcraft_atom_cmp(Atom *a1, Atom *a2);

    # Return a given atom's cpv, e.g. the atom "=cat/pkg-1-r2" has a cpv of "cat/pkg-1-r2".
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_cpv(Atom *atom);

    # Free an atom.
    #
    # # Safety
    # The argument must be a Atom pointer or NULL.
    void pkgcraft_atom_free(Atom *atom);

    # Return the hash value for a given atom.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    uint64_t pkgcraft_atom_hash(Atom *atom);

    # Return a given atom's key, e.g. the atom "=cat/pkg-1-r2" has a key of "cat/pkg".
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_key(Atom *atom);

    # Return a given atom's package, e.g. the atom "=cat/pkg-1-r2" has a package of "pkg".
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_package(Atom *atom);

    # Return a given atom's repo, e.g. the atom "=cat/pkg-1-r2:3/4::repo" has a repo of "repo".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_repo(Atom *atom);

    # Return a given atom's revision, e.g. the atom "=cat/pkg-1-r2" has a revision of "2".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_revision(Atom *atom);

    # Return a given atom's slot, e.g. the atom "=cat/pkg-1-r2:3" has a slot of "3".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_slot(Atom *atom);

    # Return a given atom's slot operator, e.g. the atom "=cat/pkg-1-r2:0=" has a slot operator of
    # "=".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_slot_op(Atom *atom);

    # Return the string for a given atom.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_str(Atom *atom);

    # Return a given atom's subslot, e.g. the atom "=cat/pkg-1-r2:3/4" has a subslot of "4".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_subslot(Atom *atom);

    # Return a given atom's USE dependencies, e.g. the atom "=cat/pkg-1-r2[a,b,c]" has USE
    # dependencies of "a, b, c".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char **pkgcraft_atom_use_deps(Atom *atom, uintptr_t *len);

    # Return a given atom's version, e.g. the atom "=cat/pkg-1-r2" has a version of "1-r2".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Atom pointer. Also, note that the returned pointer
    # is borrowed from its related Atom object and should never be freed manually.
    const Version *pkgcraft_atom_version(Atom *atom);

    # Return the pkgcraft config for the system.
    #
    # Returns NULL on error.
    Config *pkgcraft_config();

    # Add an external repo to a config.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The path argument should be a valid path on the system.
    const Repo *pkgcraft_config_add_repo(Config *config, const char *id, int priority, char *path);

    # Free a config.
    #
    # # Safety
    # The argument must be a Config pointer or NULL.
    void pkgcraft_config_free(Config *config);

    # Return the repos for a config.
    #
    # # Safety
    # The config argument must be a non-null Config pointer.
    RepoConfig **pkgcraft_config_repos(Config *config, uintptr_t *len);

    # Parse a CPV string into an atom.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should be a UTF-8 string.
    Atom *pkgcraft_cpv(char *s);

    # Get the most recent error message.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The caller is expected to free the error string using pkgcraft_str_free().
    char *pkgcraft_last_error();

    # Parse an atom string.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The atom argument should be a UTF-8 string while eapi can be a string or may be
    # NULL to use the default EAPI.
    char *pkgcraft_parse_atom(char *atom, const char *eapi);

    # Parse an atom category string.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should point to a UTF-8 string.
    const char *pkgcraft_parse_category(const char *s);

    # Parse an atom cpv string.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should point to a UTF-8 string.
    const char *pkgcraft_parse_cpv(const char *s);

    # Parse an atom package string.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should point to a UTF-8 string.
    const char *pkgcraft_parse_package(const char *s);

    # Parse an atom repo string.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should point to a UTF-8 string.
    const char *pkgcraft_parse_repo(const char *s);

    # Parse an atom version string.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should point to a UTF-8 string.
    const char *pkgcraft_parse_version(const char *s);

    # Return a given package's atom.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    const Atom *pkgcraft_pkg_atom(Pkg *p);

    # Compare two packages returning -1, 0, or 1 if the first package is less than, equal to, or
    # greater than the second package, respectively.
    #
    # # Safety
    # The arguments must be non-null Pkg pointers.
    int pkgcraft_pkg_cmp(Pkg *p1, Pkg *p2);

    # Free an package.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer or NULL.
    void pkgcraft_pkg_free(Pkg *p);

    # Return the hash value for a given package.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    uint64_t pkgcraft_pkg_hash(Pkg *p);

    # Compare two repos returning -1, 0, or 1 if the first repo is less than, equal to, or greater
    # than the second repo, respectively.
    #
    # # Safety
    # The arguments must be non-null Repo pointers.
    int pkgcraft_repo_cmp(Repo *r1, Repo *r2);

    # Return the hash value for a given repo.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    uint64_t pkgcraft_repo_hash(Repo *r);

    # Return a given repo's id.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    char *pkgcraft_repo_id(Repo *r);

    # Return a package iterator for a given repo.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    PkgIter *pkgcraft_repo_iter(Repo *r);

    # Free a repo iterator.
    #
    # # Safety
    # The argument must be a non-null PkgIter pointer or NULL.
    void pkgcraft_repo_iter_free(PkgIter *i);

    # Return the next package from a given package iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null PkgIter pointer.
    Pkg *pkgcraft_repo_iter_next(PkgIter *i);

    # Return a given repo's length.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    uintptr_t pkgcraft_repo_len(Repo *r);

    # Free an array of configured repos.
    #
    # # Safety
    # The argument must be the value received from pkgcraft_config_repos() or NULL along with the
    # length of the array.
    void pkgcraft_repos_free(RepoConfig **repos, uintptr_t len);

    # Free an array of strings.
    #
    # # Safety
    # The argument must be a pointer to a string array or NULL along with the length of the array.
    void pkgcraft_str_array_free(char **strs, uintptr_t len);

    # Free a string.
    #
    # # Safety
    # The argument must be a string pointer or NULL.
    void pkgcraft_str_free(char *s);

    # Parse a string into a version.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The version argument should point to a valid string.
    Version *pkgcraft_version(const char *version);

    # Compare two versions returning -1, 0, or 1 if the first version is less than, equal to, or greater
    # than the second version, respectively.
    #
    # # Safety
    # The version arguments should be non-null Version pointers received from pkgcraft_version().
    int pkgcraft_version_cmp(Version *v1, Version *v2);

    # Free a version.
    #
    # # Safety
    # The version argument should be a non-null Version pointer received from pkgcraft_version().
    void pkgcraft_version_free(Version *version);

    # Return the hash value for a given version.
    #
    # # Safety
    # The version argument should be a non-null Version pointer received from pkgcraft_version().
    uint64_t pkgcraft_version_hash(Version *version);

    # Return a given version's revision, e.g. the version "1-r2" has a revision of "2".
    #
    # # Safety
    # The version argument should be a non-null Version pointer received from pkgcraft_version().
    char *pkgcraft_version_revision(Version *version);

    # Return the string for a given version.
    #
    # # Safety
    # The version argument should be a non-null Version pointer received from pkgcraft_version().
    char *pkgcraft_version_str(Version *version);

    # Parse a string into a version with an operator.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The version argument should point to a valid string.
    Version *pkgcraft_version_with_op(const char *version);
