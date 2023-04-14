import pytest
from pkgcore.ebuild.atom import atom as pkgcore_dep

from pkgcraft.dep import Dep as pkgcraft_dep
from pkgcraft.repo import RepoSet

pytest_plugins = ("benchmark", "pkgcraft")


@pytest.mark.parametrize("lib", ("pkgcraft", "pkgcore"))
def test_bench_ebuild_repo_iter(benchmark, lib, ebuild_repo):
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


@pytest.mark.parametrize("lib,func", (("pkgcraft", pkgcraft_dep), ("pkgcore", pkgcore_dep)))
def test_bench_ebuild_repo_iter_restrict_dep(benchmark, lib, func, ebuild_repo):
    # create ebuilds
    for i in range(100):
        ebuild_repo.create_ebuild(f"cat/pkg-{i}")

    # single dep restriction
    dep = func("=cat/pkg-50")

    if lib == "pkgcore":
        from pkgcore.ebuild import repo_objs, repository

        repo_config = repo_objs.RepoConfig(
            location=str(ebuild_repo.path), disable_inst_caching=True
        )
        r = repository.UnconfiguredTree(str(ebuild_repo.path), repo_config=repo_config)
        pkgs = benchmark(lambda x: list(r.itermatch(x)), dep)
    else:
        pkgs = benchmark(lambda x: list(ebuild_repo.iter(x)), dep)

    assert len(pkgs) == 1
    assert str(pkgs[0].version) == "50"


def test_bench_fake_repo_iter(benchmark, fake_repo):
    # create pkgs
    fake_repo.extend([f"cat/pkg-{i}" for i in range(100)])
    pkgs = benchmark(lambda x: list(iter(x)), fake_repo)
    assert len(pkgs) == 100


def test_bench_fake_repo_iter_restrict_dep(benchmark, fake_repo):
    # create pkgs
    fake_repo.extend([f"cat/pkg-{i}" for i in range(100)])

    # single dep restriction
    dep = pkgcraft_dep("=cat/pkg-50")

    pkgs = benchmark(lambda x: list(fake_repo.iter(x)), dep)
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


def test_bench_repo_set_iter_restrict_dep(benchmark, make_ebuild_repo):
    r1 = make_ebuild_repo()
    r2 = make_ebuild_repo()
    # create ebuilds
    for i in range(50):
        r1.create_ebuild(f"cat/pkg-{i}")
    for i in range(50, 100):
        r2.create_ebuild(f"cat/pkg-{i}")

    # single dep restriction
    dep = pkgcraft_dep("=cat/pkg-50")

    repos = RepoSet(r1, r2)
    pkgs = benchmark(lambda x: list(repos.iter(x)), dep)

    assert len(pkgs) == 1
    assert str(pkgs[0].version) == "50"
