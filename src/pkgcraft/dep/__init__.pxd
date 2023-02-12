# TODO: use proper relative imports when fixed upstream
# https://github.com/cython/cython/pull/4552
from .dep.base cimport (AllOf, AnyOf, AtMostOneOf, Dep, Disabled, Enabled, ExactlyOneOf,
                        UseDisabled, UseEnabled)
from .dep.pkg cimport Cpv, PkgDep
from .dep.set cimport Dependencies, DepSet, License, Properties, RequiredUse, Restrict, SrcUri, Uri
from .dep.version cimport Version, VersionWithOp
