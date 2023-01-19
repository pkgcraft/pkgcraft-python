import pytest

pytest_plugins = ("benchmark", "pkgcraft")

from pkgcore.ebuild.atom import atom as pkgcore_atom

from pkgcraft.atom import Atom
from pkgcraft.repo import RepoSet


@pytest.mark.parametrize("lib,func", (("pkgcraft", Atom), ("pkgcore", pkgcore_atom)))
def test_bench_ebuild_repo_iter(benchmark, lib, func, ebuild_repo):
    # create ebuilds
    for i in range(100):
        ebuild_repo.create_ebuild(f"cat/pkg-{i}")

    if lib == "pkgcore":
        from pkgcore.ebuild import repo_objs, repository

        repo_config = repo_objs.RepoConfig(
            location=str(ebuild_repo.path), disable_inst_caching=True
        )
        r = repository.UnconfiguredTree(str(ebuild_repo.path), repo_config=repo_config)
        pkgs = benchmark(lambda x: list(iter(x)), r)
    else:
        pkgs = benchmark(lambda x: list(iter(x)), ebuild_repo)

    assert len(pkgs) == 100


@pytest.mark.parametrize("lib,func", (("pkgcraft", Atom), ("pkgcore", pkgcore_atom)))
def test_bench_ebuild_repo_iter_restrict_atom(benchmark, lib, func, ebuild_repo):
    # create ebuilds
    for i in range(100):
        ebuild_repo.create_ebuild(f"cat/pkg-{i}")

    # single atom restriction
    atom = func("=cat/pkg-50")

    if lib == "pkgcore":
        from pkgcore.ebuild import repo_objs, repository

        repo_config = repo_objs.RepoConfig(
            location=str(ebuild_repo.path), disable_inst_caching=True
        )
        r = repository.UnconfiguredTree(str(ebuild_repo.path), repo_config=repo_config)
        pkgs = benchmark(lambda x: list(r.itermatch(x)), atom)
    else:
        pkgs = benchmark(lambda x: list(ebuild_repo.iter_restrict(x)), atom)

    assert len(pkgs) == 1
    assert str(pkgs[0].version) == "50"


def test_bench_fake_repo_iter(benchmark, fake_repo):
    # create pkgs
    fake_repo.extend([f"cat/pkg-{i}" for i in range(100)])
    pkgs = benchmark(lambda x: list(iter(x)), fake_repo)
    assert len(pkgs) == 100


def test_bench_fake_repo_iter_restrict_atom(benchmark, fake_repo):
    # create pkgs
    fake_repo.extend([f"cat/pkg-{i}" for i in range(100)])

    # single atom restriction
    atom = Atom("=cat/pkg-50")

    pkgs = benchmark(lambda x: list(fake_repo.iter_restrict(x)), atom)
    assert len(pkgs) == 1
    assert str(pkgs[0].version) == "50"


def test_bench_repo_set_iter(benchmark, make_ebuild_repo):
    r1 = make_ebuild_repo()
    r2 = make_ebuild_repo()
    # create ebuilds
    for i in range(50):
        r1.create_ebuild(f"cat/pkg-{i}")
    for i in range(50, 100):
        r2.create_ebuild(f"cat/pkg-{i}")

    repos = RepoSet(r1, r2)
    pkgs = benchmark(lambda x: list(iter(x)), repos)
    assert len(pkgs) == 100


def test_bench_repo_set_iter_restrict_atom(benchmark, make_ebuild_repo):
    r1 = make_ebuild_repo()
    r2 = make_ebuild_repo()
    # create ebuilds
    for i in range(50):
        r1.create_ebuild(f"cat/pkg-{i}")
    for i in range(50, 100):
        r2.create_ebuild(f"cat/pkg-{i}")

    # single atom restriction
    atom = Atom("=cat/pkg-50")

    repos = RepoSet(r1, r2)
    pkgs = benchmark(lambda x: list(repos.iter_restrict(x)), atom)

    assert len(pkgs) == 1
    assert str(pkgs[0].version) == "50"
