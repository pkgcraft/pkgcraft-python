import pytest
from pkgcore.ebuild.atom import atom as pkgcore_dep
from portage.dep import Atom as portage_dep

from pkgcraft.dep import Dep as pkgcraft_dep

pytest_plugins = ("benchmark", "pkgcraft")


def random_dep(func, random_str):
    cat = random_str()
    pkg = random_str()
    s = f"=cat_{cat}/pkg_{pkg}-1-r2:3/4=[a,b,c]"
    return func(s)


dep_funcs = [
    ("pkgcraft", pkgcraft_dep),
    ("pkgcraft", pkgcraft_dep.cached),
    ("pkgcore", pkgcore_dep),
    ("portage", portage_dep),
]


@pytest.mark.parametrize("_lib,func", dep_funcs)
def test_bench_dep_static(benchmark, _lib, func):
    benchmark(func, "=cat/pkg-1-r2:3/4=[a,b,c]")


@pytest.mark.parametrize("_lib,func", dep_funcs)
def test_bench_dep_random(benchmark, random_str, _lib, func):
    benchmark(random_dep, func, random_str)


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
