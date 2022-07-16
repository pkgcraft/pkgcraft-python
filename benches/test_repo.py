import pytest
pytest_plugins = ['pkgcraft']

from pkgcraft.atom import Atom as pkgcraft_atom
from pkgcore.ebuild.atom import atom as pkgcore_atom

# TODO: generate repo metadata before running benchmark
@pytest.mark.parametrize("lib,func", (('pkgcraft', pkgcraft_atom), ('pkgcore', pkgcore_atom)))
def test_bench_iter_restrict(benchmark, lib, func, repo):
    # create ebuilds
    for i in range(100):
        repo.create_ebuild(f'cat/pkg-{i}')

    # single atom restriction
    atom = func('=cat/pkg-50')

    if lib == 'pkgcore':
        from pkgcore.ebuild import repo_objs, repository
        repo_config = repo_objs.RepoConfig(location=repo.path, disable_inst_caching=True)
        r = repository.UnconfiguredTree(repo.path, repo_config=repo_config)
        pkgs = benchmark(lambda x: list(r.itermatch(x)), atom)
    else:
        from pkgcraft.config import Config
        c = Config()
        r = c.add_repo_path(repo.path)
        pkgs = benchmark(lambda x: list(r.iter_restrict(x)), atom)

    assert len(pkgs) == 1
    assert str(pkgs[0].version) == '50'
