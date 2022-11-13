# TODO: use proper relative imports when fixed upstream
# https://github.com/cython/cython/pull/4552
from .repo.base cimport Repo, repo_from_ptr
from .repo.ebuild cimport EbuildRepo
from .repo.fake cimport FakeRepo
from .repo.set cimport RepoSet
