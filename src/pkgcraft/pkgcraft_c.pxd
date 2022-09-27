# This file is auto-generated by cbindgen.

from libc.stdint cimport int8_t, int16_t, int32_t, int64_t, intptr_t
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t, uintptr_t
cdef extern from *:
    ctypedef bint bool
    ctypedef struct va_list

cdef extern from "pkgcraft.h":

    cdef enum PkgFormat:
        EbuildPkg,
        FakePkg,

    cdef enum RepoFormat:
        EbuildRepo,
        FakeRepo,
        EmptyRepo,

    cdef enum RepoSetOp:
        RepoSetAnd,
        RepoSetOr,
        RepoSetXor,
        RepoSetSub,

    # Set types of configured repos
    cdef enum RepoSetType:
        AllRepos,
        EbuildRepos,

    # Package atom
    cdef struct Atom:
        pass

    # Opaque wrapper for AtomVersion objects.
    cdef struct AtomVersion:
        pass

    # System config
    cdef struct Config:
        pass

    # Opaque wrapper for DepSet objects.
    cdef struct DepSet:
        pass

    # EAPI object.
    cdef struct Eapi:
        pass

    # Opaque wrapper for Pkg objects.
    cdef struct Pkg:
        pass

    # Opaque wrapper for Repo objects.
    cdef struct Repo:
        pass

    # Opaque wrapper for PkgIter objects.
    cdef struct RepoPkgIter:
        pass

    # Opaque wrapper for RestrictPkgIter objects.
    cdef struct RepoRestrictPkgIter:
        pass

    # Ordered set of repos
    cdef struct RepoSet:
        pass

    # Opaque wrapper for RepoSetPkgIter objects.
    cdef struct RepoSetPkgIter:
        pass

    # Opaque wrapper for RepoSetRestrictPkgIter objects.
    cdef struct RepoSetRestrictPkgIter:
        pass

    # Opaque wrapper for Restrict objects.
    cdef struct Restrict:
        pass

    # Wrapper for package maintainers.
    cdef struct Maintainer:
        char *email;
        char *name;
        char *description;
        char *maint_type;
        char *proxied;

    # Wrapper for package upstreams.
    cdef struct Upstream:
        char *site;
        char *name;

    # Parse a string into an atom using a specific EAPI. Pass NULL for the eapi argument in
    # order to parse using the latest EAPI with extensions (e.g. support for repo deps).
    #
    # Returns NULL on error.
    #
    # # Safety
    # The atom argument should be a UTF-8 string while eapi can be a string or may be
    # NULL to use the default EAPI.
    Atom *pkgcraft_atom(const char *atom, const char *eapi);

    # Return an atom's blocker status, e.g. the atom "!cat/pkg" has a weak blocker.
    #
    # Returns -1 on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    int pkgcraft_atom_blocker(Atom *atom);

    # Return an atom's category, e.g. the atom "=cat/pkg-1-r2" has a category of "cat".
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

    # Return an atom's cpv, e.g. the atom "=cat/pkg-1-r2" has a cpv of "cat/pkg-1-r2".
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_cpv(Atom *atom);

    # Free an atom.
    #
    # # Safety
    # The argument must be a Atom pointer or NULL.
    void pkgcraft_atom_free(Atom *atom);

    # Return the hash value for an atom.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    uint64_t pkgcraft_atom_hash(Atom *atom);

    # Return an atom's key, e.g. the atom "=cat/pkg-1-r2" has a key of "cat/pkg".
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_key(Atom *atom);

    # Return an atom's package, e.g. the atom "=cat/pkg-1-r2" has a package of "pkg".
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_package(Atom *atom);

    # Return an atom's repo, e.g. the atom "=cat/pkg-1-r2:3/4::repo" has a repo of "repo".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_repo(Atom *atom);

    # Return the restriction for an atom.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    Restrict *pkgcraft_atom_restrict(Atom *atom);

    # Return an atom's revision, e.g. the atom "=cat/pkg-1-r2" has a revision of "2".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_revision(Atom *atom);

    # Return an atom's slot, e.g. the atom "=cat/pkg-1-r2:3" has a slot of "3".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_slot(Atom *atom);

    # Return an atom's slot operator, e.g. the atom "=cat/pkg-1-r2:0=" has an equal slot
    # operator.
    #
    # Returns -1 on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    int pkgcraft_atom_slot_op(Atom *atom);

    # Return the string for an atom.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_str(Atom *atom);

    # Return an atom's subslot, e.g. the atom "=cat/pkg-1-r2:3/4" has a subslot of "4".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char *pkgcraft_atom_subslot(Atom *atom);

    # Return an atom's USE dependencies, e.g. the atom "=cat/pkg-1-r2[a,b,c]" has USE
    # dependencies of "a, b, c".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Atom pointer.
    char **pkgcraft_atom_use_deps(Atom *atom, uintptr_t *len);

    # Return an atom's version, e.g. the atom "=cat/pkg-1-r2" has a version of "1-r2".
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Atom pointer. Also, note that the returned pointer
    # is borrowed from its related Atom object and should never be freed manually.
    const AtomVersion *pkgcraft_atom_version(Atom *atom);

    # Return the pkgcraft config for the system.
    #
    # Returns NULL on error.
    Config *pkgcraft_config();

    # Add an external Repo to the config.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The arguments must be valid Config and Repo pointers.
    Repo *pkgcraft_config_add_repo(Config *c, Repo *r);

    # Add local repo from filesystem path.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The path argument should be a valid path on the system.
    Repo *pkgcraft_config_add_repo_path(Config *config, const char *id, int priority, const char *path);

    # Free a config.
    #
    # # Safety
    # The argument must be a Config pointer or NULL.
    void pkgcraft_config_free(Config *config);

    # Load repos from a path to a portage-compatible repos.conf directory or file.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The path argument should be a valid path on the system.
    Repo **pkgcraft_config_load_repos_conf(Config *config, const char *path, uintptr_t *len);

    # Return the repos for a config.
    #
    # # Safety
    # The config argument must be a non-null Config pointer.
    const Repo **pkgcraft_config_repos(Config *config, uintptr_t *len);

    # Return the RepoSet for a given set type.
    #
    # # Safety
    # The config argument must be a non-null Config pointer.
    RepoSet *pkgcraft_config_repos_set(Config *config, RepoSetType set_type);

    # Parse a CPV string into an atom.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument should be a UTF-8 string.
    Atom *pkgcraft_cpv(const char *s);

    # Free a DepSet.
    #
    # # Safety
    # The argument must be a DepSet pointer or NULL.
    void pkgcraft_depset_free(DepSet *d);

    # Return the formatted string for a DepSet object.
    #
    # # Safety
    # The argument must be a non-null DepSet pointer.
    char *pkgcraft_depset_str(DepSet *dep);

    # Return an EAPI's identifier.
    #
    # # Safety
    # The arguments must be a non-null Eapi pointer.
    char *pkgcraft_eapi_as_str(const Eapi *eapi);

    # Compare two Eapi objects chronologically returning -1, 0, or 1 if the first is less than, equal
    # to, or greater than the second, respectively.
    #
    # # Safety
    # The arguments must be non-null Eapi pointers.
    int pkgcraft_eapi_cmp(const Eapi *e1, const Eapi *e2);

    # Get an EAPI from its identifier.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a non-null string.
    const Eapi *pkgcraft_eapi_from_str(const char *s);

    # Check if an EAPI has a feature.
    #
    # # Safety
    # The arguments must be a non-null Eapi pointer and non-null string.
    bool pkgcraft_eapi_has(const Eapi *eapi, const char *s);

    # Return the hash value for a Eapi.
    #
    # # Safety
    # The argument must be a non-null Eapi pointer.
    uint64_t pkgcraft_eapi_hash(const Eapi *eapi);

    # Get all known EAPIS.
    #
    # # Safety
    # The returned array must be freed via pkgcraft_eapis_free().
    const Eapi **pkgcraft_eapis(uintptr_t *len);

    # Free an array of borrowed Eapi objects.
    #
    # # Safety
    # The argument must be the value received from pkgcraft_eapis(), pkgcraft_eapis_official(), or
    # NULL along with the length of the array.
    void pkgcraft_eapis_free(const Eapi **eapis, uintptr_t len);

    # Get all official EAPIS.
    #
    # # Safety
    # The returned array must be freed via pkgcraft_eapis_free().
    const Eapi **pkgcraft_eapis_official(uintptr_t *len);

    # Convert EAPI range into an array of Eapi objects.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a non-null string.
    const Eapi **pkgcraft_eapis_range(const char *s, uintptr_t *len);

    # Return a package's BDEPEND.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_ebuild_pkg_bdepend(Pkg *p);

    # Return a package's defined phases.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char **pkgcraft_ebuild_pkg_defined_phases(Pkg *p, uintptr_t *len);

    # Return a package's DEPEND.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_ebuild_pkg_depend(Pkg *p);

    # Return a package's description.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char *pkgcraft_ebuild_pkg_description(Pkg *p);

    # Return a package's ebuild file content.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char *pkgcraft_ebuild_pkg_ebuild(Pkg *p);

    # Return a package's homepage.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char **pkgcraft_ebuild_pkg_homepage(Pkg *p, uintptr_t *len);

    # Return a package's IDEPEND.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_ebuild_pkg_idepend(Pkg *p);

    # Return a package's directly inherited eclasses.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char **pkgcraft_ebuild_pkg_inherit(Pkg *p, uintptr_t *len);

    # Return a package's inherited eclasses.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char **pkgcraft_ebuild_pkg_inherited(Pkg *p, uintptr_t *len);

    # Return a package's iuse.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char **pkgcraft_ebuild_pkg_iuse(Pkg *p, uintptr_t *len);

    # Return a package's keywords.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char **pkgcraft_ebuild_pkg_keywords(Pkg *p, uintptr_t *len);

    # Return a package's LICENSE.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_ebuild_pkg_license(Pkg *p);

    # Return a package's long description.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char *pkgcraft_ebuild_pkg_long_description(Pkg *p);

    # Return a package's maintainers.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    Maintainer **pkgcraft_ebuild_pkg_maintainers(Pkg *p, uintptr_t *len);

    # Free an array of Maintainer pointers.
    #
    # # Safety
    # The argument must be the value received from pkgcraft_ebuild_pkg_maintainers() or NULL along
    # with the length of the array.
    void pkgcraft_ebuild_pkg_maintainers_free(Maintainer **maintainers, uintptr_t len);

    # Return a package's path.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char *pkgcraft_ebuild_pkg_path(Pkg *p);

    # Return a package's PDEPEND.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_ebuild_pkg_pdepend(Pkg *p);

    # Return a package's PROPERTIES.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_ebuild_pkg_properties(Pkg *p);

    # Return a package's RDEPEND.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_ebuild_pkg_rdepend(Pkg *p);

    # Return a package's REQUIRED_USE.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_ebuild_pkg_required_use(Pkg *p);

    # Return a package's RESTRICT.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_ebuild_pkg_restrict(Pkg *p);

    # Return a package's slot.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char *pkgcraft_ebuild_pkg_slot(Pkg *p);

    # Return a package's SRC_URI.
    #
    # Returns NULL on nonexistence.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    DepSet *pkgcraft_ebuild_pkg_src_uri(Pkg *p);

    # Return a package's subslot.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    char *pkgcraft_ebuild_pkg_subslot(Pkg *p);

    # Return a package's upstreams.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    Upstream **pkgcraft_ebuild_pkg_upstreams(Pkg *p, uintptr_t *len);

    # Free an array of Upstream pointers.
    #
    # # Safety
    # The argument must be the value received from pkgcraft_ebuild_pkg_upstreams() or NULL along
    # with the length of the array.
    void pkgcraft_ebuild_pkg_upstreams_free(Upstream **upstreams, uintptr_t len);

    # Return an ebuild repo's masters.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    Repo **pkgcraft_ebuild_repo_masters(Repo *r, uintptr_t *len);

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
    const char *pkgcraft_parse_atom(const char *atom, const char *eapi);

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

    # Return a package's atom.
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

    # Return a package's EAPI.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    const Eapi *pkgcraft_pkg_eapi(Pkg *p);

    # Return a package's format.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    PkgFormat pkgcraft_pkg_format(Pkg *p);

    # Free an package.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer or NULL.
    void pkgcraft_pkg_free(Pkg *p);

    # Return the hash value for a package.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    uint64_t pkgcraft_pkg_hash(Pkg *p);

    # Return a package's repo.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    const Repo *pkgcraft_pkg_repo(Pkg *p);

    # Return the restriction for a package.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    Restrict *pkgcraft_pkg_restrict(Pkg *p);

    # Return a package's version.
    #
    # # Safety
    # The argument must be a non-null Pkg pointer.
    const AtomVersion *pkgcraft_pkg_version(Pkg *p);

    # Return a repo's categories.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    char **pkgcraft_repo_categories(Repo *r, uintptr_t *len);

    # Compare two repos returning -1, 0, or 1 if the first repo is less than, equal to, or greater
    # than the second repo, respectively.
    #
    # # Safety
    # The arguments must be non-null Repo pointers.
    int pkgcraft_repo_cmp(Repo *r1, Repo *r2);

    # Determine if a path is in a repo.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    bool pkgcraft_repo_contains_path(Repo *r, const char *path);

    # Create an ebuild repo from a given path.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The path argument should be a valid path on the system.
    Repo *pkgcraft_repo_ebuild_from_path(const char *id, int priority, const char *path);

    # Create a fake repo from a given path.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The path argument should be a valid path on the system.
    Repo *pkgcraft_repo_fake_from_path(const char *id, int priority, const char *path);

    # Create a fake repo from an array of atom strings.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    Repo *pkgcraft_repo_fake_new(const char *id, int priority, char **atoms, uintptr_t len);

    # Return a repos's format.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    RepoFormat pkgcraft_repo_format(Repo *r);

    # Free a repo.
    #
    # # Safety
    # The argument must be a Repo pointer or NULL.
    void pkgcraft_repo_free(Repo *r);

    # Load a repo from a given path.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The path argument should be a valid path on the system.
    Repo *pkgcraft_repo_from_path(const char *id, int priority, const char *path);

    # Return the hash value for a repo.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    uint64_t pkgcraft_repo_hash(Repo *r);

    # Return a repo's id.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    char *pkgcraft_repo_id(Repo *r);

    # Return a package iterator for a repo.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    RepoPkgIter *pkgcraft_repo_iter(Repo *r);

    # Free a repo iterator.
    #
    # # Safety
    # The argument must be a non-null RepoPkgIter pointer or NULL.
    void pkgcraft_repo_iter_free(RepoPkgIter *i);

    # Return the next package from a package iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null RepoPkgIter pointer.
    Pkg *pkgcraft_repo_iter_next(RepoPkgIter *i);

    # Return a repo's length.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    uintptr_t pkgcraft_repo_len(Repo *r);

    # Return a repo's packages for a category.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a non-null Repo pointer and category.
    char **pkgcraft_repo_packages(Repo *r, const char *cat, uintptr_t *len);

    # Return a repo's path.
    #
    # # Safety
    # The argument must be a non-null Repo pointer.
    char *pkgcraft_repo_path(Repo *r);

    # Return a restriction package iterator for a repo.
    #
    # # Safety
    # The repo argument must be a non-null Repo pointer and the restrict argument must be a non-null
    # Restrict pointer.
    RepoRestrictPkgIter *pkgcraft_repo_restrict_iter(Repo *repo, Restrict *restrict);

    # Free a repo restriction iterator.
    #
    # # Safety
    # The argument must be a non-null RepoRestrictPkgIter pointer or NULL.
    void pkgcraft_repo_restrict_iter_free(RepoRestrictPkgIter *i);

    # Return the next package from a restriction package iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null RepoRestrictPkgIter pointer.
    Pkg *pkgcraft_repo_restrict_iter_next(RepoRestrictPkgIter *i);

    # Create a repo set.
    #
    # # Safety
    # The argument must be an array of Repo pointers.
    RepoSet *pkgcraft_repo_set(Repo **repos, uintptr_t len);

    # Perform a set operation on a repo set and repo, assigning to the set.
    #
    # # Safety
    # The arguments must be non-null RepoSet and Repo pointers.
    void pkgcraft_repo_set_assign_op_repo(RepoSetOp op, RepoSet *s, Repo *r);

    # Perform a set operation on two repo sets, assigning to the first set.
    #
    # # Safety
    # The arguments must be non-null RepoSet pointers.
    void pkgcraft_repo_set_assign_op_set(RepoSetOp op, RepoSet *s1, RepoSet *s2);

    # Compare two repo sets returning -1, 0, or 1 if the first set is less than, equal to, or greater
    # than the second set, respectively.
    #
    # # Safety
    # The arguments must be non-null RepoSet pointers.
    int pkgcraft_repo_set_cmp(RepoSet *s1, RepoSet *s2);

    # Free a repo set.
    #
    # # Safety
    # The argument must be a RepoSet pointer or NULL.
    void pkgcraft_repo_set_free(RepoSet *r);

    # Return the hash value for a repo set.
    #
    # # Safety
    # The argument must be a non-null RepoSet pointer.
    uint64_t pkgcraft_repo_set_hash(RepoSet *s);

    # Determine if a repo set is empty.
    #
    # # Safety
    # The argument must be a non-null RepoSet pointer.
    bool pkgcraft_repo_set_is_empty(RepoSet *s);

    # Return a package iterator for a repo set.
    #
    # # Safety
    # The argument must be a non-null RepoSet pointer.
    RepoSetPkgIter *pkgcraft_repo_set_iter(RepoSet *r);

    # Free a repo set iterator.
    #
    # # Safety
    # The argument must be a non-null RepoSetPkgIter pointer or NULL.
    void pkgcraft_repo_set_iter_free(RepoSetPkgIter *i);

    # Return the next package from a repo set package iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null RepoSetPkgIter pointer.
    Pkg *pkgcraft_repo_set_iter_next(RepoSetPkgIter *i);

    # Perform a set operation on a repo set and repo, creating a new set.
    #
    # # Safety
    # The arguments must be non-null RepoSet and Repo pointers.
    RepoSet *pkgcraft_repo_set_op_repo(RepoSetOp op, RepoSet *s, Repo *r);

    # Perform a set operation on two repo sets, creating a new set.
    #
    # # Safety
    # The arguments must be non-null RepoSet pointers.
    RepoSet *pkgcraft_repo_set_op_set(RepoSetOp op, RepoSet *s1, RepoSet *s2);

    # Return the ordered array of repos for a repo set.
    #
    # # Safety
    # The argument must be a non-null RepoSet pointer.
    const Repo **pkgcraft_repo_set_repos(RepoSet *s, uintptr_t *len);

    # Return a restriction package iterator for a repo set.
    #
    # # Safety
    # The repo argument must be a non-null Repo pointer and the restrict argument must be a non-null
    # Restrict pointer.
    RepoSetRestrictPkgIter *pkgcraft_repo_set_restrict_iter(RepoSet *repo, Restrict *restrict);

    # Free a repo set restriction iterator.
    #
    # # Safety
    # The argument must be a non-null RepoSetRestrictPkgIter pointer or NULL.
    void pkgcraft_repo_set_restrict_iter_free(RepoSetRestrictPkgIter *i);

    # Return the next package from a repo set restriction package iterator.
    #
    # Returns NULL when the iterator is empty.
    #
    # # Safety
    # The argument must be a non-null RepoSetRestrictPkgIter pointer.
    Pkg *pkgcraft_repo_set_restrict_iter_next(RepoSetRestrictPkgIter *i);

    # Return a repo's versions for a package.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a non-null Repo pointer, category, and package.
    char **pkgcraft_repo_versions(Repo *r, const char *cat, const char *pkg, uintptr_t *len);

    # Free an array of configured repos.
    #
    # # Safety
    # The argument must be the value received from pkgcraft_config_repos() or NULL along with the
    # length of the array.
    void pkgcraft_repos_free(Repo **repos, uintptr_t len);

    # Combine two restrictions via logical AND.
    #
    # # Safety
    # The arguments must be Restrict pointers.
    Restrict *pkgcraft_restrict_and(Restrict *r1, Restrict *r2);

    # Free a restriction.
    #
    # # Safety
    # The argument must be a Restrict pointer or NULL.
    void pkgcraft_restrict_free(Restrict *r);

    # Invert a restriction via logical NOT.
    #
    # # Safety
    # The arguments must be a Restrict pointer.
    Restrict *pkgcraft_restrict_not(Restrict *r);

    # Combine two restrictions via logical OR.
    #
    # # Safety
    # The arguments must be Restrict pointers.
    Restrict *pkgcraft_restrict_or(Restrict *r1, Restrict *r2);

    # Parse a dependency restriction.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a non-null string.
    Restrict *pkgcraft_restrict_parse_dep(const char *s);

    # Parse a package query restriction.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The argument must be a non-null string.
    Restrict *pkgcraft_restrict_parse_pkg(const char *s);

    # Combine two restrictions via logical XOR.
    #
    # # Safety
    # The arguments must be Restrict pointers.
    Restrict *pkgcraft_restrict_xor(Restrict *r1, Restrict *r2);

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
    AtomVersion *pkgcraft_version(const char *version);

    # Compare two versions returning -1, 0, or 1 if the first version is less than, equal to, or greater
    # than the second version, respectively.
    #
    # # Safety
    # The version arguments should be non-null Version pointers received from pkgcraft_version().
    int pkgcraft_version_cmp(AtomVersion *v1, AtomVersion *v2);

    # Free a version.
    #
    # # Safety
    # The version argument should be a non-null Version pointer received from pkgcraft_version().
    void pkgcraft_version_free(AtomVersion *version);

    # Return the hash value for a version.
    #
    # # Safety
    # The version argument should be a non-null Version pointer received from pkgcraft_version().
    uint64_t pkgcraft_version_hash(AtomVersion *version);

    # Return a version's revision, e.g. the version "1-r2" has a revision of "2".
    #
    # # Safety
    # The version argument should be a non-null Version pointer received from pkgcraft_version().
    char *pkgcraft_version_revision(AtomVersion *version);

    # Return the string for a version.
    #
    # # Safety
    # The version argument should be a non-null Version pointer received from pkgcraft_version().
    char *pkgcraft_version_str(AtomVersion *version);

    # Parse a string into a version with an operator.
    #
    # Returns NULL on error.
    #
    # # Safety
    # The version argument should point to a valid string.
    AtomVersion *pkgcraft_version_with_op(const char *version);
