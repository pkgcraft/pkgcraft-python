from random import randrange

import pytest
from ordered_set import OrderedSet as PyOrderedSet

from pkgcraft.types import OrderedSet as CyOrderedSet

pytest_plugins = ("benchmark",)
set_types = [("cython", CyOrderedSet), ("python", PyOrderedSet), ("standard", set)]


@pytest.mark.parametrize("_variant,cls", set_types)
def test_bench_creation(benchmark, _variant, cls):
    s = benchmark(cls, range(100))
    assert len(s) == 100


@pytest.mark.parametrize("_variant,cls", set_types)
def test_bench_add(benchmark, _variant, cls):
    s = cls(range(100))
    benchmark(s.add, randrange(200))


@pytest.mark.parametrize("_variant,cls", set_types)
def test_bench_discard(benchmark, _variant, cls):
    s = cls(range(1000))
    benchmark(s.discard, randrange(1000))


@pytest.mark.parametrize("_variant,cls", set_types)
def test_bench_contains(benchmark, _variant, cls):
    s = cls(range(1000))
    benchmark(s.__contains__, randrange(1000))
