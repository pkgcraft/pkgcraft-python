import pytest
from pkgcore.ebuild.atom import atom as pkgcore_dep
from portage.dep import Atom as portage_dep

from pkgcraft.dep import Dep as pkgcraft_dep
from pkgcraft.dep import DepCachedLru as pkgcraft_cached_dep

pytest_plugins = ("benchmark", "pkgcraft")


def random_dep(func, random_str):
    cat = random_str()
    pkg = random_str()
    s = f"=cat_{cat}/pkg_{pkg}-1-r2:3/4=[a,b,c]"
    return func(s)


dep_funcs = [
    ("pkgcraft", pkgcraft_dep),
    ("pkgcraft", pkgcraft_cached_dep),
    ("pkgcore", pkgcore_dep),
    ("portage", portage_dep),
]


@pytest.mark.parametrize("_lib,func", dep_funcs)
def test_bench_dep_static(benchmark, _lib, func):
    benchmark(func, "=cat/pkg-1-r2:3/4=[a,b,c]")


@pytest.mark.parametrize("_lib,func", dep_funcs)
def test_bench_dep_random(benchmark, random_str, _lib, func):
    benchmark(random_dep, func, random_str)


@pytest.mark.parametrize("lib", ("pkgcraft", "portage"))
def test_bench_dep_valid(benchmark, lib):
    dep = ">=cat/pkg-1-r2:3/4=[a,b,c]"

    match lib:
        case "pkgcraft":
            from pkgcraft.dep import Dep

            func = Dep.parse
        case "portage":
            from portage.dep import isvalidatom

            func = isvalidatom

    benchmark(func, dep)


@pytest.mark.parametrize("_lib,func", dep_funcs)
def test_bench_dep_property(benchmark, _lib, func):
    dep = func("=cat/pkg-1-r2:3/4=[a,b,c]")
    version = benchmark(getattr, dep, "version")
    assert "1" in str(version)


@pytest.mark.parametrize("_lib,func", dep_funcs)
def test_bench_dep_property_none(benchmark, _lib, func):
    dep = func("cat/pkg")
    version = benchmark(getattr, dep, "version")
    assert version is None


# portage deps don't natively support comparisons
@pytest.mark.parametrize("_lib,func", (("pkgcraft", pkgcraft_dep), ("pkgcore", pkgcore_dep)))
def test_bench_dep_sorting_worst_case(benchmark, _lib, func):
    deps = [func(f"=cat/pkg-{v}-r1:2/3=[a,b,c]") for v in reversed(range(100))]
    result = benchmark(sorted, deps)
    assert result == list(reversed(deps))


# portage deps don't natively support comparisons
@pytest.mark.parametrize("_lib,func", (("pkgcraft", pkgcraft_dep), ("pkgcore", pkgcore_dep)))
def test_bench_dep_sorting_best_case(benchmark, _lib, func):
    deps = [func(f"=cat/pkg-{v}-r1:2/3=[a,b,c]") for v in range(100)]
    result = benchmark(sorted, deps)
    assert result == deps


@pytest.mark.parametrize("lib", ("pkgcraft", "pkgcore", "portage"))
def test_bench_dep_without(benchmark, lib):
    dep = ">=cat/pkg-1-r2:3/4=::repo[a,b,c]"

    match lib:
        case "pkgcraft":
            dep = pkgcraft_dep(dep)
            func = lambda d: d.without("repo")
        case "pkgcore":
            # pkgcore doesn't have "without repo" functionality
            dep = pkgcore_dep(dep)
            func = lambda d: d.no_usedeps
        case "portage":
            dep = portage_dep(dep)
            func = lambda d: d.without_repo

    benchmark(func, dep)


@pytest.mark.parametrize("lib", ("pkgcraft", "portage"))
def test_bench_dep_modify(benchmark, lib):
    dep = ">=cat/pkg-1-r2:3/4=[a,b,c]"

    match lib:
        case "pkgcraft":
            dep = pkgcraft_dep(dep)
            func = lambda d: d.modify(repo="repo")
        case "portage":
            dep = portage_dep(dep)
            func = lambda d: d.with_repo("repo")

    benchmark(func, dep)
