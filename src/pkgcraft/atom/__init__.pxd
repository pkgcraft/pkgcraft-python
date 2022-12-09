# TODO: use proper relative imports when fixed upstream
# https://github.com/cython/cython/pull/4552
from .atom.base cimport Atom, Cpv
from .atom.version cimport Version, VersionWithOp
