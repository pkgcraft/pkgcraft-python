from random import randrange

import pytest

pytest_plugins = ("benchmark",)

from ordered_set import OrderedSet as PyOrderedSet

from pkgcraft.set import OrderedSet as CyOrderedSet

set_types = [("cython", CyOrderedSet), ("python", PyOrderedSet), ("standard", set)]


@pytest.mark.parametrize("variant,cls", set_types)
def test_bench_creation(benchmark, variant, cls):
    s = benchmark(cls, range(100))
    assert len(s) == 100


@pytest.mark.parametrize("variant,cls", set_types)
def test_bench_add(benchmark, variant, cls):
    s = cls(range(100))
    benchmark(s.add, randrange(200))


@pytest.mark.parametrize("variant,cls", set_types)
def test_bench_discard(benchmark, variant, cls):
    s = cls(range(1000))
    benchmark(s.discard, randrange(1000))


@pytest.mark.parametrize("variant,cls", set_types)
def test_bench_contains(benchmark, variant, cls):
    s = cls(range(1000))
    benchmark(s.__contains__, randrange(1000))
