# This file is auto-generated from pkgcraft-c using cbindgen.

from libc.stdint cimport int8_t, int16_t, int32_t, int64_t, intptr_t
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t, uintptr_t
cdef extern from *:
    ctypedef bint bool
    ctypedef struct va_list

cdef extern from "pkgcraft.h":

    cdef enum Blocker:
        BLOCKER_STRONG # = 1,
        BLOCKER_WEAK,

    cdef enum:
        DEP_FIELD_BLOCKER # = 1,
        DEP_FIELD_VERSION # = (1 << 1),
        DEP_FIELD_SLOT # = (1 << 2),
        DEP_FIELD_SUBSLOT # = (1 << 3),
        DEP_FIELD_SLOT_OP # = (1 << 4),
        DEP_FIELD_USE_DEPS # = (1 << 5),
        DEP_FIELD_REPO # = (1 << 6),
    ctypedef uint32_t DepField

    # DepSet variants.
    cdef enum DepSetKind:
        DEP_SET_KIND_DEPENDENCIES,
        DEP_SET_KIND_SRC_URI,
        DEP_SET_KIND_LICENSE,
        DEP_SET_KIND_PROPERTIES,
        DEP_SET_KIND_REQUIRED_USE,
        DEP_SET_KIND_RESTRICT,

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

    cdef enum ErrorKind:
        ERROR_KIND_GENERIC,
        ERROR_KIND_PKGCRAFT,
        ERROR_KIND_CONFIG,
        ERROR_KIND_REPO,
        ERROR_KIND_PKG,

    cdef enum LogLevel:
        LOG_LEVEL_OFF,
        LOG_LEVEL_TRACE,
        LOG_LEVEL_DEBUG,
        LOG_LEVEL_INFO,
        LOG_LEVEL_WARN,
        LOG_LEVEL_ERROR,

    cdef enum Operator:
        OPERATOR_LESS # = 1,
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

    # Repo set types registered in the config object.
    cdef enum Repos:
        REPOS_ALL,
        REPOS_EBUILD,

    # Generic set operations.
    cdef enum SetOp:
        SET_OP_AND,
        SET_OP_OR,
        SET_OP_XOR,
        SET_OP_SUB,

    cdef enum SlotOperator:
        SLOT_OPERATOR_EQUAL # = 1,
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

    # Opaque wrapper for pkgcraft::dep::spec::IntoIter<String, T>.
    cdef struct DepSpecIntoIter:
        pass

    # Opaque wrapper for pkgcraft::dep::spec::IntoIterConditionals<String, T>.
    cdef struct DepSpecIntoIterConditionals:
        pass

    # Opaque wrapper for pkgcraft::dep::spec::IntoIterFlatten<String, T>.
    cdef struct DepSpecIntoIterFlatten:
        pass

    # Opaque wrapper for pkgcraft::dep::spec::IntoIterRecursive<String, T>.
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

    # Opaque wrapper for pkgcraft::repo::IterCpv objects.
    cdef struct RepoIterCpv:
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

    cdef struct Revision:
        pass

    # Uri object.
    cdef struct Uri:
        pass

    cdef struct Version:
        pass

    # C-compatible wrapper for pkgcraft::dep::DepSet.
    cdef struct DepSet:
        DepSetKind set
        DepSetWrapper *dep

    # C-compatible wrapper for pkgcraft::dep::DepSpec.
    cdef struct DepSpec:
        DepSetKind set
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

    # Return the string for a Cpv object.
    #
    # # Safety
    # The argument must be a non-null Cpv pointer.
    char *pkgcraft_cpv_str(Cpv *c)

    # Determine if a string is a valid package Cpv.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should point to a UTF-8 string.
    const char *pkgcraft_cpv_valid(const char *s)

    # Get the version of a Cpv object.
    #
    # # Safety
    # The argument must be a non-null Cpv pointer.
    Version *pkgcraft_cpv_version(Cpv *c)

    # Get a package dependency's raw blocker value.
    # For example, the package dependency "!cat/pkg" has a weak blocker.
    #
    # Returns a value of 0 for nonexistence.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    uint32_t pkgcraft_dep_blocker(Dep *d)

    # Parse a string into a Blocker's raw value.
    #
    # Returns a value of 0 for nonexistence.
    #
    # # Safety
    # The argument must be a UTF-8 string.
    uint32_t pkgcraft_dep_blocker_from_str(const char *s)

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

    # Perform a set operation on two DepSets, assigning to the first.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The arguments must be non-null DepSet pointers.
    DepSet *pkgcraft_dep_set_assign_op_set(SetOp op, DepSet *d1, DepSet *d2)

    # Determine if a DepSet contains a given DepSpec.
    #
    # # Safety
    # The arguments must be non-null DepSet and DepSpec pointers.
    bool pkgcraft_dep_set_contains(DepSet *s, DepSpec *d)

    # Determine if two DepSets are equal.
    #
    # # Safety
    # The arguments must be non-null DepSet pointers.
    bool pkgcraft_dep_set_eq(DepSet *d1, DepSet *d2)

    # Evaluate a DepSet.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    DepSet *pkgcraft_dep_set_evaluate(DepSet *d, char **options, uintptr_t len)

    # Forcibly evaluate a DepSet.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    DepSet *pkgcraft_dep_set_evaluate_force(DepSet *d, bool force)

    # Free a DepSet.
    #
    # # Safety
    # The argument must be a DepSet pointer or NULL.
    void pkgcraft_dep_set_free(DepSet *d)

    # Create a DepSet from an array of DepSpec objects.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should be an array of similarly-typed DepSpec objects.
    DepSet *pkgcraft_dep_set_from_iter(DepSpec **deps, uintptr_t len, DepSetKind kind)

    # Returns the DepSpec element for a given index.
    #
    # Returns NULL on index nonexistence.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    DepSpec *pkgcraft_dep_set_get_index(DepSet *d, uintptr_t index)

    # Return the hash value for a DepSet.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    uint64_t pkgcraft_dep_set_hash(DepSet *d)

    # Insert a DepSpec into a DepSet.
    #
    # Returns false if an equivalent value already exists, otherwise true.
    #
    # # Safety
    # The arguments must be non-null DepSet and DepSpec pointers.
    bool pkgcraft_dep_set_insert(DepSet *d, DepSpec *value)

    # Return an iterator for a DepSet.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    DepSpecIntoIter *pkgcraft_dep_set_into_iter(DepSet *d)

    # Return a conditionals iterator for a DepSet.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    DepSpecIntoIterConditionals *pkgcraft_dep_set_into_iter_conditionals(DepSet *d)

    # Free a conditionals iterator.
    #
    # # Safety
    # The argument must be a non-null DepSpecIntoIterConditionals pointer or NULL.
    void pkgcraft_dep_set_into_iter_conditionals_free(DepSpecIntoIterConditionals *i)

    # Return the next object from a conditionals iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null DepSpecIntoIterConditionals pointer.
    char *pkgcraft_dep_set_into_iter_conditionals_next(DepSpecIntoIterConditionals *i)

    # Return a flatten iterator for a DepSet.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    DepSpecIntoIterFlatten *pkgcraft_dep_set_into_iter_flatten(DepSet *d)

    # Free a flatten iterator.
    #
    # # Safety
    # The argument must be a non-null DepSpecIntoIterFlatten pointer or NULL.
    void pkgcraft_dep_set_into_iter_flatten_free(DepSpecIntoIterFlatten *i)

    # Return the next object from a flatten iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null DepSpecIntoIterFlatten pointer.
    void *pkgcraft_dep_set_into_iter_flatten_next(DepSpecIntoIterFlatten *i)

    # Free a DepSet iterator.
    #
    # # Safety
    # The argument must be a non-null DepSpecIntoIter pointer or NULL.
    void pkgcraft_dep_set_into_iter_free(DepSpecIntoIter *i)

    # Return the next object from a DepSet iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null DepSpecIntoIter pointer.
    DepSpec *pkgcraft_dep_set_into_iter_next(DepSpecIntoIter *i)

    # Return the next object from the end of a DepSet iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null DepSpecIntoIter pointer.
    DepSpec *pkgcraft_dep_set_into_iter_next_back(DepSpecIntoIter *i)

    # Return a recursive iterator for a DepSet.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    DepSpecIntoIterRecursive *pkgcraft_dep_set_into_iter_recursive(DepSet *d)

    # Free a recursive iterator.
    #
    # # Safety
    # The argument must be a non-null DepSpecIntoIterRecursive pointer or NULL.
    void pkgcraft_dep_set_into_iter_recursive_free(DepSpecIntoIterRecursive *i)

    # Return the next object from a recursive iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null DepSpecIntoIterRecursive pointer.
    DepSpec *pkgcraft_dep_set_into_iter_recursive_next(DepSpecIntoIterRecursive *i)

    # Returns true if two DepSets have no elements in common.
    #
    # # Safety
    # The arguments must be a non-null DepSet pointers.
    bool pkgcraft_dep_set_is_disjoint(DepSet *d1, DepSet *d2)

    # Returns true if a DepSet is empty.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    bool pkgcraft_dep_set_is_empty(DepSet *d)

    # Returns true if all the elements of the first DepSet are contained in the second.
    #
    # # Safety
    # The arguments must be a non-null DepSet pointers.
    bool pkgcraft_dep_set_is_subset(DepSet *d1, DepSet *d2)

    # Return a DepSet's length.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    uintptr_t pkgcraft_dep_set_len(DepSet *d)

    # Perform a set operation on two DepSets, creating a new set.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The arguments must be non-null DepSet pointers.
    DepSet *pkgcraft_dep_set_op_set(SetOp op, DepSet *d1, DepSet *d2)

    # Parse a string into a specified DepSet type.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should be a UTF-8 string.
    DepSet *pkgcraft_dep_set_parse(const char *s, const Eapi *eapi, DepSetKind kind)

    # Remove the last value from a DepSet.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    DepSpec *pkgcraft_dep_set_pop(DepSet *d)

    # Replace a DepSpec with another DepSpec in a DepSet, returning the replaced value.
    #
    # Returns NULL on nonexistence or if the DepSet already contains the given DepSpec.
    #
    # # Safety
    # The arguments must be non-null DepSet and DepSpec pointers.
    DepSpec *pkgcraft_dep_set_replace(DepSet *d, const DepSpec *key, DepSpec *value)

    # Replace a DepSpec for a given index in a DepSet, returning the replaced value.
    #
    # Returns NULL on index nonexistence or if the DepSet already contains the given DepSpec.
    #
    # # Safety
    # The arguments must be non-null DepSet and DepSpec pointers.
    DepSpec *pkgcraft_dep_set_replace_index(DepSet *d, uintptr_t index, DepSpec *value)

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

    # Get a package dependency's raw slot operator value.
    # For example, the package dependency "=cat/pkg-1-r2:0=" has an equal slot operator.
    #
    # Returns a value of 0 for nonexistence.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    uint32_t pkgcraft_dep_slot_op(Dep *d)

    # Parse a string into a SlotOperator's raw value.
    #
    # Returns a value of 0 for nonexistence.
    #
    # # Safety
    # The argument must be a UTF-8 string.
    uint32_t pkgcraft_dep_slot_op_from_str(const char *s)

    # Return the string for a SlotOperator.
    char *pkgcraft_dep_slot_op_str(SlotOperator op)

    # Compare two DepSpecs returning -1, 0, or 1 if the first is less than, equal to, or greater
    # than the second, respectively.
    #
    # # Safety
    # The arguments must be non-null DepSpec pointers.
    int pkgcraft_dep_spec_cmp(DepSpec *d1, DepSpec *d2)

    # Determine if a DepSpec contains a given DepSpec.
    #
    # # Safety
    # The arguments must be non-null DepSpec pointers.
    bool pkgcraft_dep_spec_contains(DepSpec *d1, DepSpec *d2)

    # Evaluate a DepSpec.
    #
    # # Safety
    # The argument must be a non-null DepSpec pointer.
    DepSpec **pkgcraft_dep_spec_evaluate(DepSpec *d,
                                         char **options,
                                         uintptr_t len,
                                         uintptr_t *deps_len)

    # Forcibly evaluate a DepSpec.
    #
    # # Safety
    # The argument must be a non-null DepSpec pointer.
    DepSpec **pkgcraft_dep_spec_evaluate_force(DepSpec *d, bool force, uintptr_t *deps_len)

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

    # Return an iterator for a DepSpec.
    #
    # # Safety
    # The argument must be a non-null DepSpec pointer.
    DepSpecIntoIter *pkgcraft_dep_spec_into_iter(DepSpec *d)

    # Return a conditionals iterator for a DepSpec.
    #
    # # Safety
    # The argument must be a non-null DepSpec pointer.
    DepSpecIntoIterConditionals *pkgcraft_dep_spec_into_iter_conditionals(DepSpec *d)

    # Return a flatten iterator for a DepSpec.
    #
    # # Safety
    # The argument must be a non-null DepSpec pointer.
    DepSpecIntoIterFlatten *pkgcraft_dep_spec_into_iter_flatten(DepSpec *d)

    # Return a recursive iterator for a DepSpec.
    #
    # # Safety
    # The argument must be a non-null DepSpec pointer.
    DepSpecIntoIterRecursive *pkgcraft_dep_spec_into_iter_recursive(DepSpec *d)

    # Return a DepSpec's length.
    #
    # # Safety
    # The argument must be a non-null DepSpec pointer.
    uintptr_t pkgcraft_dep_spec_len(DepSpec *d)

    # Parse a string into a specified DepSpec type.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should be a UTF-8 string.
    DepSpec *pkgcraft_dep_spec_parse(const char *s, const Eapi *eapi, DepSetKind kind)

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

    # Determine if a string is a valid package dependency.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The eapi argument may be NULL to use the default EAPI.
    const char *pkgcraft_dep_valid(const char *s, const Eapi *eapi)

    # Get the version of a package dependency.
    # For example, the package dependency "=cat/pkg-1-r2" returns "1-r2".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Dep pointer.
    Version *pkgcraft_dep_version(Dep *d)

    # Return a given package dependency without the specified fields.
    #
    # # Safety
    # The arguments must be a non-null Dep pointer and a DepFields bitflag.
    Dep *pkgcraft_dep_without(Dep *d, uint32_t fields)

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
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_pkg_ebuild_pdepend(Pkg *p)

    # Return a package's PROPERTIES.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_pkg_ebuild_properties(Pkg *p)

    # Return a package's RDEPEND.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_pkg_ebuild_rdepend(Pkg *p)

    # Return a package's REQUIRED_USE.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_pkg_ebuild_required_use(Pkg *p)

    # Return a package's RESTRICT.
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

    # Return a Cpv iterator for a repo.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    RepoIterCpv *pkgcraft_repo_iter_cpv(Repo *r)

    # Free a repo Cpv iterator.
    #
    # # Safety
    # The argument must be a non-null RepoIterCpv pointer or NULL.
    void pkgcraft_repo_iter_cpv_free(RepoIterCpv *i)

    # Return the next Cpv from a repo Cpv iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null RepoIterCpv pointer.
    Cpv *pkgcraft_repo_iter_cpv_next(RepoIterCpv *i)

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
    void pkgcraft_repo_set_assign_op_repo(SetOp op, RepoSet *s, Repo *r)

    # Perform a set operation on two repo sets, assigning to the first set.
    #
    # # Safety
    # The arguments must be non-null RepoSet pointers.
    void pkgcraft_repo_set_assign_op_set(SetOp op, RepoSet *s1, RepoSet *s2)

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
    RepoSet *pkgcraft_repo_set_op_repo(SetOp op, RepoSet *s, Repo *r)

    # Perform a set operation on two repo sets, creating a new set.
    #
    # # Safety
    # The arguments must be non-null RepoSet pointers.
    RepoSet *pkgcraft_repo_set_op_set(SetOp op, RepoSet *s1, RepoSet *s2)

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

    # Compare two revisions returning -1, 0, or 1 if the first is less than, equal to, or greater
    # than the second, respectively.
    #
    # # Safety
    # The revision arguments should be non-null Revision pointers.
    int pkgcraft_revision_cmp(Revision *r1, Revision *r2)

    # Free a revision.
    #
    # # Safety
    # The revision argument should be a non-null Revision pointer.
    void pkgcraft_revision_free(Revision *r)

    # Return the hash value for a revision.
    #
    # # Safety
    # The revision argument should be a non-null Revision pointer.
    uint64_t pkgcraft_revision_hash(Revision *r)

    # Parse a string into a revision.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should be a valid UTF-8 string.
    Revision *pkgcraft_revision_new(const char *s)

    # Return a revision's string value.
    #
    # # Safety
    # The revision argument should be a non-null Revision pointer.
    char *pkgcraft_revision_str(Revision *r)

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

    # Compare two versions returning -1, 0, or 1 if the first is less than, equal to, or greater than
    # the second, respectively.
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

    # Return a version operator's raw value.
    #
    # Returns a value of 0 for nonexistence.
    #
    # # Safety
    # The argument must be a non-null Version pointer.
    uint32_t pkgcraft_version_op(Version *v)

    # Parse a string into an Operator's raw value.
    #
    # Returns a value of 0 for nonexistence.
    #
    # # Safety
    # The argument should be a UTF-8 string.
    uint32_t pkgcraft_version_op_from_str(const char *s)

    # Return the string for an Operator.
    char *pkgcraft_version_op_str(Operator op)

    # Return a version's revision, e.g. the version "1-r2" has a revision of "2".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The version argument should be a non-null Version pointer.
    Revision *pkgcraft_version_revision(Version *v)

    # Return a version's string value without operator.
    #
    # # Safety
    # The version argument should be a non-null Version pointer.
    char *pkgcraft_version_str(Version *v)

    # Determine if a string is a valid package version.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should point to a UTF-8 string.
    const char *pkgcraft_version_valid(const char *s)
