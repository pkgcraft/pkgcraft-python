# TODO: use proper relative imports when fixed upstream
# https://github.com/cython/cython/pull/4552
from .dep.pkg cimport Cpv, Dep
from .dep.set cimport Dependencies, DepSet, License, Properties, RequiredUse, Restrict, SrcUri, Uri
from .dep.spec cimport (AllOf, AnyOf, AtMostOneOf, DepSpec, Disabled, Enabled, ExactlyOneOf,
                        UseDisabled, UseEnabled)
from .dep.version cimport Version, VersionWithOp
