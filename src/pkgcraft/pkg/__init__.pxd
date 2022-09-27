# TODO: use proper relative imports when fixed upstream
# https://github.com/cython/cython/pull/4552
from .pkg.base cimport Pkg
from .pkg.ebuild cimport EbuildPkg
from .pkg.fake cimport FakePkg
