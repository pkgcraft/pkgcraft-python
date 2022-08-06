[![CI](https://github.com/pkgcraft/pkgcraft-python/workflows/CI/badge.svg)](https://github.com/pkgcraft/pkgcraft-python/actions/workflows/ci.yml)
[![coverage](https://codecov.io/gh/pkgcraft/pkgcraft-python/branch/main/graph/badge.svg)](https://codecov.io/gh/pkgcraft/pkgcraft-python)

# pkgcraft-python

Python bindings for pkgcraft.

## Development

Requirements: >=python-3.9, [tox](https://pypi.org/project/tox/),
[valgrind](https://valgrind.org/), and everything required to build
[pkgcraft-c](https://github.com/pkgcraft/pkgcraft-c)

Use the following commands to set up a dev environment:

```bash
# clone the pkgcraft workspace and pull the latest project updates
git clone --recurse-submodules https://github.com/pkgcraft/pkgcraft-workspace.git
cd pkgcraft-workspace
git submodule update --recursive --remote

# build pkgcraft-c library and set shell variables (e.g. $PKG_CONFIG_PATH)
source ./build pkgcraft-c

cd pkgcraft-python
# build and test
tox -e python
# test under valgrind
tox -e valgrind
# run benchmarks
tox -e bench
# run memory usage benchmarks
tox -e membench
```
