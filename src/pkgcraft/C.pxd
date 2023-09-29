# This file is auto-generated from pkgcraft-c using cbindgen.

from libc.stdint cimport int8_t, int16_t, int32_t, int64_t, intptr_t
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t, uintptr_t
cdef extern from *:
    ctypedef bint bool
    ctypedef struct va_list

cdef extern from "pkgcraft.h":

    cdef enum Blocker:
        BLOCKER_NONE,
        BLOCKER_STRONG,
        BLOCKER_WEAK,

    # DepSet variants.
    cdef enum DepSetKind:
        DEP_SET_KIND_DEPENDENCIES,
        DEP_SET_KIND_LICENSE,
        DEP_SET_KIND_PROPERTIES,
        DEP_SET_KIND_REQUIRED_USE,
        DEP_SET_KIND_RESTRICT,
        DEP_SET_KIND_SRC_URI,

    # DepSpec variants.
    cdef enum DepSpecKind:
        DEP_SPEC_KIND_ENABLED,
        DEP_SPEC_KIND_DISABLED,
        DEP_SPEC_KIND_ALL_OF,
        DEP_SPEC_KIND_ANY_OF,
        DEP_SPEC_KIND_EXACTLY_ONE_OF,
        DEP_SPEC_KIND_AT_MOST_ONE_OF,
        DEP_SPEC_KIND_USE_ENABLED,
        DEP_SPEC_KIND_USE_DISABLED,

    # DepSpec unit variants.
    cdef enum DepSpecUnit:
        DEP_SPEC_UNIT_DEP,
        DEP_SPEC_UNIT_STRING,
        DEP_SPEC_UNIT_URI,

    cdef enum ErrorKind:
        ERROR_KIND_GENERIC,
        ERROR_KIND_PKGCRAFT,
        ERROR_KIND_CONFIG,
        ERROR_KIND_REPO,

    cdef enum LogLevel:
        LOG_LEVEL_OFF,
        LOG_LEVEL_TRACE,
        LOG_LEVEL_DEBUG,
        LOG_LEVEL_INFO,
        LOG_LEVEL_WARN,
        LOG_LEVEL_ERROR,

    cdef enum Operator:
        OPERATOR_NONE,
        OPERATOR_LESS,
        OPERATOR_LESS_OR_EQUAL,
        OPERATOR_EQUAL,
        OPERATOR_EQUAL_GLOB,
        OPERATOR_APPROXIMATE,
        OPERATOR_GREATER_OR_EQUAL,
        OPERATOR_GREATER,

    cdef enum PkgFormat:
        PKG_FORMAT_CONFIGURED,
        PKG_FORMAT_EBUILD,
        PKG_FORMAT_FAKE,

    # Supported repo formats
    cdef enum RepoFormat:
        REPO_FORMAT_EBUILD,
        REPO_FORMAT_FAKE,
        REPO_FORMAT_EMPTY,

    cdef enum RepoSetOp:
        REPO_SET_OP_AND,
        REPO_SET_OP_OR,
        REPO_SET_OP_XOR,
        REPO_SET_OP_SUB,

    # Repo set types registered in the config object.
    cdef enum Repos:
        REPOS_ALL,
        REPOS_EBUILD,

    cdef enum SlotOperator:
        SLOT_OPERATOR_NONE,
        SLOT_OPERATOR_EQUAL,
        SLOT_OPERATOR_STAR,

    # System config
    cdef struct Config:
        pass

    # Package identifier.
    cdef struct Cpv:
        pass

    # Package dependency.
    cdef struct Dep:
        pass

    # Opaque wrapper for pkgcraft::dep::DepSet.
    cdef struct DepSetWrapper:
        pass

    # Opaque wrapper for pkgcraft::dep::spec::IntoIter<T>.
    cdef struct DepSpecIntoIter:
        pass

    # Opaque wrapper for pkgcraft::dep::spec::IntoIterFlatten<T>.
    cdef struct DepSpecIntoIterFlatten:
        pass

    # Opaque wrapper for pkgcraft::dep::spec::IntoIterRecursive<T>.
    cdef struct DepSpecIntoIterRecursive:
        pass

    # Opaque wrapper for pkgcraft::dep::DepSpec.
    cdef struct DepSpecWrapper:
        pass

    # EAPI object.
    cdef struct Eapi:
        pass

    # Opaque wrapper for pkgcraft::repo::temp::Repo objects.
    cdef struct EbuildTempRepo:
        pass

    # Opaque wrapper for pkgcraft::pkg::Pkg objects.
    cdef struct Pkg:
        pass

    # Opaque wrapper for pkgcraft::repo::Repo objects.
    cdef struct Repo:
        pass

    # Opaque wrapper for pkgcraft::repo::Iter objects.
    cdef struct RepoIter:
        pass

    # Opaque wrapper for pkgcraft::repo::IterRestrict objects.
    cdef struct RepoIterRestrict:
        pass

    # Ordered set of repos
    cdef struct RepoSet:
        pass

    # Opaque wrapper for pkgcraft::repo::set::Iter objects.
    cdef struct RepoSetIter:
        pass

    # Opaque wrapper for pkgcraft::restrict::Restrict objects.
    cdef struct Restrict:
        pass

    # Uri object.
    cdef struct Uri:
        pass

    cdef struct Version:
        pass

    # C-compatible wrapper for pkgcraft::dep::DepSet.
    cdef struct DepSet:
        DepSpecUnit unit
        DepSetKind kind
        DepSetWrapper *dep

    # C-compatible wrapper for pkgcraft::dep::DepSpec.
    cdef struct DepSpec:
        DepSpecUnit unit
        DepSpecKind kind
        DepSpecWrapper *dep

    cdef struct PkgcraftError:
        char *message
        ErrorKind kind

    cdef struct PkgcraftLog:
        char *message
        LogLevel level

    ctypedef void (*LogCallback)(PkgcraftLog*)

    # Wrapper for package maintainers.
    cdef struct Maintainer:
        char *email
        char *name
        char *description
        char *maint_type
        char *proxied

    # Wrapper for package upstream remote-ids.
    cdef struct RemoteId:
        char *site
        char *name

    # Wrapper for upstream package maintainers.
    cdef struct UpstreamMaintainer:
        char *name
        char *email
        char *status

    # Wrapper for package upstream info.
    cdef struct Upstream:
        uintptr_t remote_ids_len
        RemoteId **remote_ids
        uintptr_t maintainers_len
        UpstreamMaintainer **maintainers
        char *bugs_to
        char *changelog
        char *doc

    # Free an array without dropping the objects inside it.
    #
    # # Safety
    # The array objects should be explicitly dropped using other methods otherwise they will leak.
    void pkgcraft_array_free(void **array, uintptr_t len)

    # Add an external Repo to the config.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The arguments must be valid Config and Repo pointers.
    Repo *pkgcraft_config_add_repo(Config *c, Repo *r, bool external)

    # Add local repo from filesystem path.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The path argument should be a valid path on the system.
    Repo *pkgcraft_config_add_repo_path(Config *c,
                                        const char *id,
                                        int priority,
                                        const char *path,
                                        bool external)

    # Free a config.
    #
    # # Safety
    # The argument must be a Config pointer or NULL.
    void pkgcraft_config_free(Config *c)

    # Load the system config.
    #
    # Returns NULL on error.
    #
    # # Safety
    # A valid pkgcraft (or portage config) directory should be located on the system.
    Config *pkgcraft_config_load(Config *c)

    # Load the portage config from a given path, use NULL for the default system paths.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The path argument should be a valid path on the system.
    Config *pkgcraft_config_load_portage_conf(Config *c, const char *path)

    # Create an empty pkgcraft config.
    Config *pkgcraft_config_new()

    # Return the repos for a config.
    #
    # # Safety
    # The config argument must be a non-null Config pointer.
    const Repo **pkgcraft_config_repos(Config *c, uintptr_t *len)

    # Return the RepoSet for a given set type.
    #
    # # Safety
    # The config argument must be a non-null Config pointer.
    RepoSet *pkgcraft_config_repos_set(Config *c, Repos kind)

    # Get the category of a Cpv object.
    #
    # # Safety
    # The argument must be a non-null Cpv pointer.
    char *pkgcraft_cpv_category(Cpv *c)

    # Compare two Cpvs returning -1, 0, or 1 if the first is less than, equal to, or
    # greater than the second, respectively.
    #
    # # Safety
    # The arguments must be non-null Cpv pointers.
    int pkgcraft_cpv_cmp(Cpv *c1, Cpv *c2)

    # Get the category and package of a Cpv object.
    #
    # # Safety
    # The argument must be a non-null Cpv pointer.
    char *pkgcraft_cpv_cpn(Cpv *c)

    # Free a Cpv.
    #
    # # Safety
    # The argument must be a Cpv pointer or NULL.
    void pkgcraft_cpv_free(Cpv *c)

    # Return the hash value for a Cpv object.
    #
    # # Safety
    # The argument must be a non-null Cpv pointer.
    uint64_t pkgcraft_cpv_hash(Cpv *c)

    # Determine if two Cpv objects intersect.
    #
    # # Safety
    # The arguments must be non-null Cpv pointers.
    bool pkgcraft_cpv_intersects(Cpv *c1, Cpv *c2)

    # Determine if a Cpv intersects with a package dependency.
    #
    # # Safety
    # The arguments must be non-null Cpv and Dep pointers.
    bool pkgcraft_cpv_intersects_dep(Cpv *c, Dep *d)

    # Parse a CPV string into a Cpv object.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should be a UTF-8 string.
    Cpv *pkgcraft_cpv_new(const char *s)

    # Get the package and revision of a Cpv object.
    #
    # # Safety
    # The argument must be a non-null Cpv pointer.
    char *pkgcraft_cpv_p(Cpv *c)

    # Get the package name of a Cpv object.
    #
    # # Safety
    # The argument must be a non-null Cpv pointer.
    char *pkgcraft_cpv_package(Cpv *c)

    # Get the package, version, and revision of a Cpv object.
    #
    # # Safety
    # The argument must be a non-null Cpv pointer.
    char *pkgcraft_cpv_pf(Cpv *c)

    # Get the revision of a Cpv object.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Cpv pointer.
    char *pkgcraft_cpv_pr(Cpv *c)

    # Get the version of a Cpv object.
    #
    # # Safety
    # The argument must be a non-null Cpv pointer.
    char *pkgcraft_cpv_pv(Cpv *c)

    # Get the version and revision of a Cpv object.
    #
    # # Safety
    # The argument must be a non-null Cpv pointer.
    char *pkgcraft_cpv_pvr(Cpv *c)

    # Return the restriction for a Cpv object.
    #
    # # Safety
    # The argument must be a non-null Cpv pointer.
    Restrict *pkgcraft_cpv_restrict(Cpv *c)

    # Determine if a restriction matches a Cpv object.
    #
    # # Safety
    # The arguments must be valid Restrict and Cpv pointers.
    bool pkgcraft_cpv_restrict_matches(Cpv *c, Restrict *r)

    # Get the revision of a Cpv object.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Cpv pointer.
    char *pkgcraft_cpv_revision(Cpv *c)

    # Return the string for a Cpv object.
    #
    # # Safety
    # The argument must be a non-null Cpv pointer.
    char *pkgcraft_cpv_str(Cpv *c)

    # Get the version of a Cpv object.
    #
    # # Safety
    # The argument must be a non-null Cpv pointer.
    Version *pkgcraft_cpv_version(Cpv *c)

    # Get the blocker of a package dependency.
    # For example, the package dependency "!cat/pkg" has a weak blocker.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    Blocker pkgcraft_dep_blocker(Dep *d)

    # Parse a string into a Blocker.
    #
    # # Safety
    # The argument must be a UTF-8 string.
    Blocker pkgcraft_dep_blocker_from_str(const char *s)

    # Return the string for a Blocker.
    char *pkgcraft_dep_blocker_str(Blocker b)

    # Get the category of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2" returns "cat".
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    char *pkgcraft_dep_category(Dep *d)

    # Compare two package dependencies returning -1, 0, or 1 if the first is less than, equal to, or
    # greater than the second, respectively.
    #
    # # Safety
    # The arguments must be non-null Dep pointers.
    int pkgcraft_dep_cmp(Dep *d1, Dep *d2)

    # Get the category and package of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2" returns "cat/pkg".
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    char *pkgcraft_dep_cpn(Dep *d)

    # Get the category, package, and version of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2" returns "cat/pkg-1-r2".
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    char *pkgcraft_dep_cpv(Dep *d)

    # Free a package dependency.
    #
    # # Safety
    # The argument must be a Dep pointer or NULL.
    void pkgcraft_dep_free(Dep *d)

    # Return the hash value for a package dependency.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    uint64_t pkgcraft_dep_hash(Dep *d)

    # Determine if two package dependencies intersect.
    #
    # # Safety
    # The arguments must be non-null Dep pointers.
    bool pkgcraft_dep_intersects(Dep *d1, Dep *d2)

    # Determine if a package dependency intersects with a Cpv.
    #
    # # Safety
    # The arguments must be non-null Cpv and Dep pointers.
    bool pkgcraft_dep_intersects_cpv(Dep *d, Cpv *c)

    # Parse a string into a package dependency using a specific EAPI. Pass NULL for the eapi argument
    # in order to parse using the latest EAPI with extensions (e.g. support for repo deps).
    #
    # Returns NULL on error.
    #
    # # Safety
    # The eapi argument may be NULL to use the default EAPI.
    Dep *pkgcraft_dep_new(const char *s,
                          const Eapi *eapi)

    # Parse a string into an unversioned package dependency.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a UTF-8 string.
    Dep *pkgcraft_dep_new_cpn(const char *s)

    # Get the package and revision of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2" returns "pkg-1".
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    char *pkgcraft_dep_p(Dep *d)

    # Get the package name of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2" returns "pkg".
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    char *pkgcraft_dep_package(Dep *d)

    # Get the package, version, and revision of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2" returns "pkg-1-r2".
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    char *pkgcraft_dep_pf(Dep *d)

    # Get the revision of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2" returns "r2".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    char *pkgcraft_dep_pr(Dep *d)

    # Get the version of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2" returns "1".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    char *pkgcraft_dep_pv(Dep *d)

    # Get the version and revision of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2" returns "1-r2".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    char *pkgcraft_dep_pvr(Dep *d)

    # Get the repo of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2:3/4::repo" returns "repo".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    char *pkgcraft_dep_repo(Dep *d)

    # Return the restriction for a package dependency.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    Restrict *pkgcraft_dep_restrict(Dep *d)

    # Determine if a restriction matches a package dependency.
    #
    # # Safety
    # The arguments must be valid Restrict and Dep pointers.
    bool pkgcraft_dep_restrict_matches(Dep *d, Restrict *r)

    # Get the revision of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2" returns "2".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    char *pkgcraft_dep_revision(Dep *d)

    # Parse a string into a Dependencies DepSet.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should be a UTF-8 string.
    DepSet *pkgcraft_dep_set_dependencies(const char *s, const Eapi *eapi)

    # Determine if two DepSets are equal.
    #
    # # Safety
    # The arguments must be non-null DepSet pointers.
    bool pkgcraft_dep_set_eq(DepSet *d1, DepSet *d2)

    # Free a DepSet.
    #
    # # Safety
    # The argument must be a DepSet pointer or NULL.
    void pkgcraft_dep_set_free(DepSet *d)

    # Return the hash value for a DepSet.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    uint64_t pkgcraft_dep_set_hash(DepSet *d)

    # Return an iterator for a depset.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    DepSpecIntoIter *pkgcraft_dep_set_into_iter(DepSet *d)

    # Return a flattened iterator for a DepSet.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    DepSpecIntoIterFlatten *pkgcraft_dep_set_into_iter_flatten(DepSet *d)

    # Free a flattened depset iterator.
    #
    # # Safety
    # The argument must be a non-null DepSpecIntoIterFlatten pointer or NULL.
    void pkgcraft_dep_set_into_iter_flatten_free(DepSpecIntoIterFlatten *i)

    # Return the next object from a flattened depset iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null DepSpecIntoIterFlatten pointer.
    void *pkgcraft_dep_set_into_iter_flatten_next(DepSpecIntoIterFlatten *i)

    # Free a depset iterator.
    #
    # # Safety
    # The argument must be a non-null DepSpecIntoIter pointer or NULL.
    void pkgcraft_dep_set_into_iter_free(DepSpecIntoIter *i)

    # Return the next object from a depset iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null DepSpecIntoIter pointer.
    DepSpec *pkgcraft_dep_set_into_iter_next(DepSpecIntoIter *i)

    # Return a recursive iterator for a DepSet.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    DepSpecIntoIterRecursive *pkgcraft_dep_set_into_iter_recursive(DepSet *d)

    # Free a recursive depset iterator.
    #
    # # Safety
    # The argument must be a non-null DepSpecIntoIterFlatten pointer or NULL.
    void pkgcraft_dep_set_into_iter_recursive_free(DepSpecIntoIterRecursive *i)

    # Return the next object from a recursive depset iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null DepSpecIntoIterRecursive pointer.
    DepSpec *pkgcraft_dep_set_into_iter_recursive_next(DepSpecIntoIterRecursive *i)

    # Parse a string into a License DepSet.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should be a UTF-8 string.
    DepSet *pkgcraft_dep_set_license(const char *s)

    # Parse a string into a Properties DepSet.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should be a UTF-8 string.
    DepSet *pkgcraft_dep_set_properties(const char *s)

    # Parse a string into a RequiredUse DepSet.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should be a UTF-8 string.
    DepSet *pkgcraft_dep_set_required_use(const char *s, const Eapi *eapi)

    # Parse a string into a Restrict DepSet.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should be a UTF-8 string.
    DepSet *pkgcraft_dep_set_restrict(const char *s)

    # Parse a string into a SrcUri DepSet.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should be a UTF-8 string.
    DepSet *pkgcraft_dep_set_src_uri(const char *s, const Eapi *eapi)

    # Return the formatted string for a DepSet object.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    char *pkgcraft_dep_set_str(DepSet *d)

    # Get the slot of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2:3" returns "3".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    char *pkgcraft_dep_slot(Dep *d)

    # Get the slot operator of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2:0=" has an equal slot operator.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    SlotOperator pkgcraft_dep_slot_op(Dep *d)

    # Parse a string into a SlotOperator.
    #
    # # Safety
    # The argument must be a UTF-8 string.
    SlotOperator pkgcraft_dep_slot_op_from_str(const char *s)

    # Return the string for a SlotOperator.
    char *pkgcraft_dep_slot_op_str(SlotOperator op)

    # Compare two DepSpecs returning -1, 0, or 1 if the first is less than, equal to, or greater
    # than the second, respectively.
    #
    # # Safety
    # The arguments must be non-null DepSpec pointers.
    int pkgcraft_dep_spec_cmp(DepSpec *d1, DepSpec *d2)

    # Free a DepSpec object.
    #
    # # Safety
    # The argument must be a DepSpec pointer or NULL.
    void pkgcraft_dep_spec_free(DepSpec *r)

    # Return the hash value for a DepSpec.
    #
    # # Safety
    # The argument must be a non-null DepSpec pointer.
    uint64_t pkgcraft_dep_spec_hash(DepSpec *d)

    # Return a flattened iterator for a DepSpec.
    #
    # # Safety
    # The argument must be a non-null DepSpec pointer.
    DepSpecIntoIterFlatten *pkgcraft_dep_spec_into_iter_flatten(DepSpec *d)

    # Return a recursive iterator for a DepSpec.
    #
    # # Safety
    # The argument must be a non-null DepSpec pointer.
    DepSpecIntoIterRecursive *pkgcraft_dep_spec_into_iter_recursive(DepSpec *d)

    # Return the formatted string for a DepSpec object.
    #
    # # Safety
    # The argument must be a non-null DepSpec pointer.
    char *pkgcraft_dep_spec_str(DepSpec *d)

    # Return the string for a package dependency.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    char *pkgcraft_dep_str(Dep *d)

    # Get the subslot of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2:3/4" returns "4".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    char *pkgcraft_dep_subslot(Dep *d)

    # Get the USE dependencies of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2[a,b,c]" has USE dependencies of "a, b, c".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    char **pkgcraft_dep_use_deps(Dep *d, uintptr_t *len)

    # Get the version of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2" returns "1-r2".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    Version *pkgcraft_dep_version(Dep *d)

    # Return an EAPI's identifier.
    #
    # # Safety
    # The arguments must be a non-null Eapi pointer.
    char *pkgcraft_eapi_as_str(const Eapi *eapi)

    # Compare two Eapi objects chronologically returning -1, 0, or 1 if the first is less than, equal
    # to, or greater than the second, respectively.
    #
    # # Safety
    # The arguments must be non-null Eapi pointers.
    int pkgcraft_eapi_cmp(const Eapi *e1,
                          const Eapi *e2)

    # Return the array of dependency keys for an Eapi.
    #
    # # Safety
    # The argument must be a non-null Eapi pointer.
    char **pkgcraft_eapi_dep_keys(const Eapi *eapi, uintptr_t *len)

    # Get an EAPI from its identifier.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a non-null string.
    const Eapi *pkgcraft_eapi_from_str(const char *s)

    # Check if an EAPI has a feature.
    #
    # # Safety
    # The arguments must be a non-null Eapi pointer and non-null string.
    bool pkgcraft_eapi_has(const Eapi *eapi, const char *s)

    # Return the hash value for an Eapi.
    #
    # # Safety
    # The argument must be a non-null Eapi pointer.
    uint64_t pkgcraft_eapi_hash(const Eapi *eapi)

    # Return the array of metadata keys for an Eapi.
    #
    # # Safety
    # The argument must be a non-null Eapi pointer.
    char **pkgcraft_eapi_metadata_keys(const Eapi *eapi, uintptr_t *len)

    # Get all known EAPIS.
    #
    # # Safety
    # The returned array must be freed via pkgcraft_eapis_free().
    const Eapi **pkgcraft_eapis(uintptr_t *len)

    # Get all official EAPIS.
    #
    # # Safety
    # The returned array must be freed via pkgcraft_eapis_free().
    const Eapi **pkgcraft_eapis_official(uintptr_t *len)

    # Convert EAPI range into an array of Eapi objects.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a non-null string.
    const Eapi **pkgcraft_eapis_range(const char *s, uintptr_t *len)

    # Free an error.
    #
    # # Safety
    # The argument must be a non-null PkgcraftError pointer or NULL.
    void pkgcraft_error_free(PkgcraftError *e)

    # Get the most recent error, returns NULL if none exists.
    PkgcraftError *pkgcraft_error_last()

    # Return the library version.
    char *pkgcraft_lib_version()

    # Free a log.
    #
    # # Safety
    # The argument must be a non-null PkgcraftLog pointer or NULL.
    void pkgcraft_log_free(PkgcraftLog *l)

    # Replay a given PkgcraftLog object for test purposes.
    #
    # # Safety
    # The argument must be a non-null PkgcraftLog pointer.
    void pkgcraft_log_test(const char *msg, LogLevel level)

    # Enable pkgcraft logging support.
    void pkgcraft_logging_enable(LogCallback cb, LogLevel level)

    # Parse a package category.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should point to a UTF-8 string.
    const char *pkgcraft_parse_category(const char *s)

    # Parse a package CPV.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should point to a UTF-8 string.
    const char *pkgcraft_parse_cpv(const char *s)

    # Parse a package dependency.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The eapi argument may be NULL to use the default EAPI.
    const char *pkgcraft_parse_dep(const char *s, const Eapi *eapi)

    # Parse a package name.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should point to a UTF-8 string.
    const char *pkgcraft_parse_package(const char *s)

    # Parse a package repo.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should point to a UTF-8 string.
    const char *pkgcraft_parse_repo(const char *s)

    # Parse a package version.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should point to a UTF-8 string.
    const char *pkgcraft_parse_version(const char *s)

    # Compare two packages returning -1, 0, or 1 if the first package is less than, equal to, or
    # greater than the second package, respectively.
    #
    # # Safety
    # The arguments must be non-null Pkg pointers.
    int pkgcraft_pkg_cmp(Pkg *p1, Pkg *p2)

    # Return a package's CPV.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    Cpv *pkgcraft_pkg_cpv(Pkg *p)

    # Return a package's EAPI.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    const Eapi *pkgcraft_pkg_eapi(Pkg *p)

    # Return a package's BDEPEND.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_pkg_ebuild_bdepend(Pkg *p)

    # Return a package's defined phases.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char **pkgcraft_pkg_ebuild_defined_phases(Pkg *p, uintptr_t *len)

    # Return a package's DEPEND.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_pkg_ebuild_depend(Pkg *p)

    # Return a package's dependencies for a given set of descriptors.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_pkg_ebuild_dependencies(Pkg *p, char **keys, uintptr_t len)

    # Return a package's description.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char *pkgcraft_pkg_ebuild_description(Pkg *p)

    # Return a package's ebuild file content.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char *pkgcraft_pkg_ebuild_ebuild(Pkg *p)

    # Return a package's homepage.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char **pkgcraft_pkg_ebuild_homepage(Pkg *p, uintptr_t *len)

    # Return a package's IDEPEND.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_pkg_ebuild_idepend(Pkg *p)

    # Return a package's directly inherited eclasses.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char **pkgcraft_pkg_ebuild_inherit(Pkg *p, uintptr_t *len)

    # Return a package's inherited eclasses.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char **pkgcraft_pkg_ebuild_inherited(Pkg *p, uintptr_t *len)

    # Return a package's iuse.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char **pkgcraft_pkg_ebuild_iuse(Pkg *p, uintptr_t *len)

    # Return a package's keywords.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char **pkgcraft_pkg_ebuild_keywords(Pkg *p, uintptr_t *len)

    # Return a package's LICENSE.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_pkg_ebuild_license(Pkg *p)

    # Return a package's long description.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char *pkgcraft_pkg_ebuild_long_description(Pkg *p)

    # Return a package's maintainers.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    Maintainer **pkgcraft_pkg_ebuild_maintainers(Pkg *p, uintptr_t *len)

    # Free an array of Maintainer pointers.
    #
    # # Safety
    # The argument must be the value received from pkgcraft_pkg_ebuild_maintainers() or NULL along
    # with the length of the array.
    void pkgcraft_pkg_ebuild_maintainers_free(Maintainer **maintainers, uintptr_t len)

    # Return a package's path.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char *pkgcraft_pkg_ebuild_path(Pkg *p)

    # Return a package's PDEPEND.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_pkg_ebuild_pdepend(Pkg *p)

    # Return a package's PROPERTIES.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_pkg_ebuild_properties(Pkg *p)

    # Return a package's RDEPEND.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_pkg_ebuild_rdepend(Pkg *p)

    # Return a package's REQUIRED_USE.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_pkg_ebuild_required_use(Pkg *p)

    # Return a package's RESTRICT.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_pkg_ebuild_restrict(Pkg *p)

    # Return a package's slot.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char *pkgcraft_pkg_ebuild_slot(Pkg *p)

    # Return a package's SRC_URI.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_pkg_ebuild_src_uri(Pkg *p)

    # Return a package's subslot.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char *pkgcraft_pkg_ebuild_subslot(Pkg *p)

    # Return a package's upstream info.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    Upstream *pkgcraft_pkg_ebuild_upstream(Pkg *p)

    # Free an Upstream.
    #
    # # Safety
    # The argument must be a Upstream pointer or NULL.
    void pkgcraft_pkg_ebuild_upstream_free(Upstream *u)

    # Return a package's format.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    PkgFormat pkgcraft_pkg_format(Pkg *p)

    # Free an package.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer or NULL.
    void pkgcraft_pkg_free(Pkg *p)

    # Return the hash value for a package.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    uint64_t pkgcraft_pkg_hash(Pkg *p)

    # Return a package's repo.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    const Repo *pkgcraft_pkg_repo(Pkg *p)

    # Return the restriction for a package.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    Restrict *pkgcraft_pkg_restrict(Pkg *p)

    # Determine if a restriction matches a package.
    #
    # # Safety
    # The arguments must be valid Restrict and Pkg pointers.
    bool pkgcraft_pkg_restrict_matches(Pkg *p, Restrict *r)

    # Return the string for a package.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char *pkgcraft_pkg_str(Pkg *p)

    # Return a package's version.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    Version *pkgcraft_pkg_version(Pkg *p)

    # Return a repo's categories.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    char **pkgcraft_repo_categories(Repo *r, uintptr_t *len)

    # Compare two repos returning -1, 0, or 1 if the first repo is less than, equal to, or greater
    # than the second repo, respectively.
    #
    # # Safety
    # The arguments must be non-null Repo pointers.
    int pkgcraft_repo_cmp(Repo *r1, Repo *r2)

    # Determine if a path is in a repo.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    bool pkgcraft_repo_contains_path(Repo *r, const char *path)

    # Return an ebuild repo's EAPI.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    const Eapi *pkgcraft_repo_ebuild_eapi(Repo *r)

    # Return an ebuild repo's masters.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    Repo **pkgcraft_repo_ebuild_masters(Repo *r, uintptr_t *len)

    # Return an ebuild repo's metadata arches.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    char **pkgcraft_repo_ebuild_metadata_arches(Repo *r, uintptr_t *len)

    # Return an ebuild repo's metadata categories.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    char **pkgcraft_repo_ebuild_metadata_categories(Repo *r, uintptr_t *len)

    # Regenerate an ebuild repo's package metadata cache.
    #
    # Returns false on error, otherwise true.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    bool pkgcraft_repo_ebuild_pkg_metadata_regen(Repo *r, uintptr_t jobs, bool force)

    # Create an ebuild file in the repo.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a non-null EbuildTempRepo pointer.
    char *pkgcraft_repo_ebuild_temp_create_ebuild(EbuildTempRepo *r,
                                                  const char *cpv,
                                                  char **key_vals,
                                                  uintptr_t len)

    # Create an ebuild file in the repo from raw data.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a non-null EbuildTempRepo pointer.
    char *pkgcraft_repo_ebuild_temp_create_ebuild_raw(EbuildTempRepo *r,
                                                      const char *cpv,
                                                      const char *data)

    # Free a temporary repo.
    #
    # Freeing a temporary repo removes the related directory from the filesystem.
    #
    # # Safety
    # The argument must be a EbuildTempRepo pointer or NULL.
    void pkgcraft_repo_ebuild_temp_free(EbuildTempRepo *r)

    # Create a temporary ebuild repository.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The id argument should be a valid, unicode string and the eapi parameter can optionally be
    # NULL.
    EbuildTempRepo *pkgcraft_repo_ebuild_temp_new(const char *id, const Eapi *eapi)

    # Return a temporary repo's path.
    #
    # # Safety
    # The argument must be a non-null EbuildTempRepo pointer.
    char *pkgcraft_repo_ebuild_temp_path(EbuildTempRepo *r)

    # Persist a temporary repo to disk, returning its path.
    #
    # # Safety
    # The related EbuildTempRepo pointer is invalid on function completion and should not be used.
    char *pkgcraft_repo_ebuild_temp_persist(EbuildTempRepo *r, const char *path)

    # Add pkgs to an existing fake repo from an array of CPV strings.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The arguments must be a non-null Repo pointer and an array of CPV strings.
    Repo *pkgcraft_repo_fake_extend(Repo *r, char **cpvs, uintptr_t len)

    # Create a fake repo from an array of CPV strings.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The cpvs argument should be valid CPV strings.
    Repo *pkgcraft_repo_fake_new(const char *id, int priority, char **cpvs, uintptr_t len)

    # Return a repos's format.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    RepoFormat pkgcraft_repo_format(Repo *r)

    # Free a repo.
    #
    # # Safety
    # The argument must be a Repo pointer or NULL.
    void pkgcraft_repo_free(Repo *r)

    # Try to load a certain repo type from a given path.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The path argument should be a valid path on the system.
    Repo *pkgcraft_repo_from_format(RepoFormat format,
                                    const char *id,
                                    int priority,
                                    const char *path,
                                    bool finalize)

    # Load a repo from a given path.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The path argument should be a valid path on the system.
    Repo *pkgcraft_repo_from_path(const char *id, int priority, const char *path, bool finalize)

    # Return the hash value for a repo.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    uint64_t pkgcraft_repo_hash(Repo *r)

    # Return a repo's id.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    char *pkgcraft_repo_id(Repo *r)

    # Determine if a repo is empty.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    bool pkgcraft_repo_is_empty(Repo *r)

    # Return a package iterator for a repo.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    RepoIter *pkgcraft_repo_iter(Repo *r)

    # Free a repo iterator.
    #
    # # Safety
    # The argument must be a non-null RepoIter pointer or NULL.
    void pkgcraft_repo_iter_free(RepoIter *i)

    # Return the next package from a package iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null RepoIter pointer.
    Pkg *pkgcraft_repo_iter_next(RepoIter *i)

    # Return a restriction package iterator for a repo.
    #
    # # Safety
    # The repo argument must be a non-null Repo pointer and the restrict argument must be a non-null
    # Restrict pointer.
    RepoIterRestrict *pkgcraft_repo_iter_restrict(Repo *repo, Restrict *restrict)

    # Free a repo restriction iterator.
    #
    # # Safety
    # The argument must be a non-null RepoIterRestrict pointer or NULL.
    void pkgcraft_repo_iter_restrict_free(RepoIterRestrict *i)

    # Return the next package from a restriction package iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null RepoIterRestrict pointer.
    Pkg *pkgcraft_repo_iter_restrict_next(RepoIterRestrict *i)

    # Return a repo's length.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    uintptr_t pkgcraft_repo_len(Repo *r)

    # Return a repo's packages for a category.
    #
    # # Safety
    # The arguments must be a non-null Repo pointer and category.
    char **pkgcraft_repo_packages(Repo *r, const char *cat, uintptr_t *len)

    # Return a repo's path.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    char *pkgcraft_repo_path(Repo *r)

    # Perform a set operation on a repo set and repo, assigning to the set.
    #
    # # Safety
    # The arguments must be non-null RepoSet and Repo pointers.
    void pkgcraft_repo_set_assign_op_repo(RepoSetOp op, RepoSet *s, Repo *r)

    # Perform a set operation on two repo sets, assigning to the first set.
    #
    # # Safety
    # The arguments must be non-null RepoSet pointers.
    void pkgcraft_repo_set_assign_op_set(RepoSetOp op, RepoSet *s1, RepoSet *s2)

    # Return a repo set's categories.
    #
    # # Safety
    # The argument must be a non-null RepoSet pointer.
    char **pkgcraft_repo_set_categories(RepoSet *s, uintptr_t *len)

    # Compare two repo sets returning -1, 0, or 1 if the first set is less than, equal to, or greater
    # than the second set, respectively.
    #
    # # Safety
    # The arguments must be non-null RepoSet pointers.
    int pkgcraft_repo_set_cmp(RepoSet *s1,
                              RepoSet *s2)

    # Free a repo set.
    #
    # # Safety
    # The argument must be a RepoSet pointer or NULL.
    void pkgcraft_repo_set_free(RepoSet *r)

    # Return the hash value for a repo set.
    #
    # # Safety
    # The argument must be a non-null RepoSet pointer.
    uint64_t pkgcraft_repo_set_hash(RepoSet *s)

    # Determine if a repo set is empty.
    #
    # # Safety
    # The argument must be a non-null RepoSet pointer.
    bool pkgcraft_repo_set_is_empty(RepoSet *s)

    # Return a package iterator for a repo set.
    #
    # # Safety
    # The repo argument must be a non-null Repo pointer and the restrict argument can be a
    # Restrict pointer or NULL to iterate over all packages.
    RepoSetIter *pkgcraft_repo_set_iter(RepoSet *s, Restrict *restrict)

    # Free a repo set iterator.
    #
    # # Safety
    # The argument must be a non-null RepoSetIter pointer or NULL.
    void pkgcraft_repo_set_iter_free(RepoSetIter *i)

    # Return the next package from a repo set package iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null RepoSetIter pointer.
    Pkg *pkgcraft_repo_set_iter_next(RepoSetIter *i)

    # Return a repo set's length.
    #
    # # Safety
    # The argument must be a non-null RepoSet pointer.
    uintptr_t pkgcraft_repo_set_len(RepoSet *s)

    # Create a repo set.
    #
    # # Safety
    # The argument must be an array of Repo pointers.
    RepoSet *pkgcraft_repo_set_new(Repo **repos, uintptr_t len)

    # Perform a set operation on a repo set and repo, creating a new set.
    #
    # # Safety
    # The arguments must be non-null RepoSet and Repo pointers.
    RepoSet *pkgcraft_repo_set_op_repo(RepoSetOp op, RepoSet *s, Repo *r)

    # Perform a set operation on two repo sets, creating a new set.
    #
    # # Safety
    # The arguments must be non-null RepoSet pointers.
    RepoSet *pkgcraft_repo_set_op_set(RepoSetOp op, RepoSet *s1, RepoSet *s2)

    # Return a repo set's packages for a category.
    #
    # # Safety
    # The arguments must be a non-null RepoSet pointer and category.
    char **pkgcraft_repo_set_packages(RepoSet *s, const char *cat, uintptr_t *len)

    # Return the ordered array of repos for a repo set.
    #
    # # Safety
    # The argument must be a non-null RepoSet pointer.
    const Repo **pkgcraft_repo_set_repos(RepoSet *s, uintptr_t *len)

    # Return a repo set's versions for a package.
    #
    # # Safety
    # The arguments must be a non-null RepoSet pointer, category, and package.
    Version **pkgcraft_repo_set_versions(RepoSet *s,
                                         const char *cat,
                                         const char *pkg,
                                         uintptr_t *len)

    # Return a repo's versions for a package.
    #
    # # Safety
    # The arguments must be a non-null Repo pointer, category, and package.
    Version **pkgcraft_repo_versions(Repo *r, const char *cat, const char *pkg, uintptr_t *len)

    # Create a new restriction combining two restrictions via logical AND.
    #
    # # Safety
    # The arguments must be Restrict pointers.
    Restrict *pkgcraft_restrict_and(Restrict *r1, Restrict *r2)

    # Determine if two restrictions are equal.
    #
    # # Safety
    # The arguments must be non-null Restrict pointers.
    bool pkgcraft_restrict_eq(Restrict *r1, Restrict *r2)

    # Free a restriction.
    #
    # # Safety
    # The argument must be a Restrict pointer or NULL.
    void pkgcraft_restrict_free(Restrict *r)

    # Return the hash value for a restriction.
    #
    # # Safety
    # The argument must be a non-null Restrict pointer.
    uint64_t pkgcraft_restrict_hash(Restrict *r)

    # Create a new restriction inverting a restriction via logical NOT.
    #
    # # Safety
    # The arguments must be a Restrict pointer.
    Restrict *pkgcraft_restrict_not(Restrict *r)

    # Create a new restriction combining two restrictions via logical OR.
    #
    # # Safety
    # The arguments must be Restrict pointers.
    Restrict *pkgcraft_restrict_or(Restrict *r1, Restrict *r2)

    # Parse a dependency restriction.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a non-null string.
    Restrict *pkgcraft_restrict_parse_dep(const char *s)

    # Parse a package query restriction.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a non-null string.
    Restrict *pkgcraft_restrict_parse_pkg(const char *s)

    # Create a new restriction combining two restrictions via logical XOR.
    #
    # # Safety
    # The arguments must be Restrict pointers.
    Restrict *pkgcraft_restrict_xor(Restrict *r1, Restrict *r2)

    # Free an array of strings.
    #
    # # Safety
    # The argument must be a pointer to a string array or NULL along with the length of the array.
    void pkgcraft_str_array_free(char **strs, uintptr_t len)

    # Free a string.
    #
    # # Safety
    # The argument must be a string pointer or NULL.
    void pkgcraft_str_free(char *s)

    # Get the filename for a Uri.
    #
    # # Safety
    # The argument must be a Uri pointer.
    char *pkgcraft_uri_filename(Uri *u)

    # Free a Uri object.
    #
    # # Safety
    # The argument must be a non-null Uri pointer or NULL.
    void pkgcraft_uri_free(Uri *u)

    # Return the formatted string for a Uri object.
    #
    # # Safety
    # The argument must be a Uri pointer.
    char *pkgcraft_uri_str(Uri *u)

    # Get the main URI from a Uri object.
    #
    # # Safety
    # The argument must be a Uri pointer.
    char *pkgcraft_uri_uri(Uri *u)

    # Return a version's base, e.g. the version "1-r2" has a base of "1".
    #
    # # Safety
    # The version argument should be a non-null Version pointer.
    char *pkgcraft_version_base(Version *v)

    # Compare two versions returning -1, 0, or 1 if the first version is less than, equal to, or greater
    # than the second version, respectively.
    #
    # # Safety
    # The version arguments should be non-null Version pointers.
    int pkgcraft_version_cmp(Version *v1,
                             Version *v2)

    # Free a version.
    #
    # # Safety
    # The version argument should be a non-null Version pointer.
    void pkgcraft_version_free(Version *v)

    # Return the hash value for a version.
    #
    # # Safety
    # The version argument should be a non-null Version pointer.
    uint64_t pkgcraft_version_hash(Version *v)

    # Determine if two versions intersect.
    #
    # # Safety
    # The version arguments should be non-null Version pointers.
    bool pkgcraft_version_intersects(Version *v1, Version *v2)

    # Parse a string into a version.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The version argument should point to a valid string.
    Version *pkgcraft_version_new(const char *s)

    # Return a version's operator.
    #
    # # Safety
    # The argument must be a non-null Version pointer.
    Operator pkgcraft_version_op(Version *v)

    # Parse a string into an Operator.
    #
    # # Safety
    # The argument should be a UTF-8 string.
    Operator pkgcraft_version_op_from_str(const char *s)

    # Return the string for an Operator.
    char *pkgcraft_version_op_str(Operator op)

    # Return a version's revision, e.g. the version "1-r2" has a revision of "2".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The version argument should be a non-null Version pointer.
    char *pkgcraft_version_revision(Version *v)

    # Return a version's string value without operator.
    #
    # # Safety
    # The version argument should be a non-null Version pointer.
    char *pkgcraft_version_str(Version *v)
