# TODO: use proper relative imports when fixed upstream
# https://github.com/cython/cython/pull/4552
from .depset.base cimport DepSet, Uri
from .depset.deprestrict cimport (AllOf, AnyOf, AtMostOneOf, DepRestrict, Disabled, Enabled,
                                  ExactlyOneOf, UseDisabled, UseEnabled)
