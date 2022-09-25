import pytest
pytest_plugins = ('benchmark', 'pkgcraft')

from pkgcraft.config import Config
from pkgcraft.atom import Atom
from pkgcraft.repo import RepoSet
from pkgcore.ebuild.atom import atom as pkgcore_atom


@pytest.mark.parametrize("lib,func", (('pkgcraft', Atom), ('pkgcore', pkgcore_atom)))
def test_bench_repo_iter(benchmark, lib, func, repo):
    # create ebuilds
    for i in range(100):
        repo.create_ebuild(f'cat/pkg-{i}')

    if lib == 'pkgcore':
        from pkgcore.ebuild import repo_objs, repository
        repo_config = repo_objs.RepoConfig(location=str(repo.path), disable_inst_caching=True)
        r = repository.UnconfiguredTree(str(repo.path), repo_config=repo_config)
        pkgs = benchmark(lambda x: list(iter(x)), r)
    else:
        pkgs = benchmark(lambda x: list(iter(x)), repo)

    assert len(pkgs) == 100


def test_bench_repo_set_iter(benchmark, make_repo):
    config = Config()
    repo1 = make_repo(config=config)
    repo2 = make_repo(config=config)
    # create ebuilds
    for i in range(50):
        repo1.create_ebuild(f'cat/pkg-{i}')
    for i in range(50, 100):
        repo2.create_ebuild(f'cat/pkg-{i}')

    repo = RepoSet([repo1, repo2])
    pkgs = benchmark(lambda x: list(iter(x)), repo)
    assert len(pkgs) == 100


@pytest.mark.parametrize("lib,func", (('pkgcraft', Atom), ('pkgcore', pkgcore_atom)))
def test_bench_repo_iter_restrict_atom(benchmark, lib, func, repo):
    # create ebuilds
    for i in range(100):
        repo.create_ebuild(f'cat/pkg-{i}')

    # single atom restriction
    atom = func('=cat/pkg-50')

    if lib == 'pkgcore':
        from pkgcore.ebuild import repo_objs, repository
        repo_config = repo_objs.RepoConfig(location=str(repo.path), disable_inst_caching=True)
        r = repository.UnconfiguredTree(str(repo.path), repo_config=repo_config)
        pkgs = benchmark(lambda x: list(r.itermatch(x)), atom)
    else:
        pkgs = benchmark(lambda x: list(repo.iter_restrict(x)), atom)

    assert len(pkgs) == 1
    assert str(pkgs[0].version) == '50'


def test_bench_repo_set_iter_restrict_atom(benchmark, make_repo):
    config = Config()
    repo1 = make_repo(config=config)
    repo2 = make_repo(config=config)
    # create ebuilds
    for i in range(50):
        repo1.create_ebuild(f'cat/pkg-{i}')
    for i in range(50, 100):
        repo2.create_ebuild(f'cat/pkg-{i}')

    # single atom restriction
    atom = Atom('=cat/pkg-50')

    repo = RepoSet([repo1, repo2])
    pkgs = benchmark(lambda x: list(repo.iter_restrict(x)), atom)

    assert len(pkgs) == 1
    assert str(pkgs[0].version) == '50'
