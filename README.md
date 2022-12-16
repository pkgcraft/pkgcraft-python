[![CI](https://github.com/pkgcraft/pkgcraft-python/workflows/CI/badge.svg)](https://github.com/pkgcraft/pkgcraft-python/actions/workflows/ci.yml)
[![coverage](https://codecov.io/gh/pkgcraft/pkgcraft-python/branch/main/graph/badge.svg)](https://codecov.io/gh/pkgcraft/pkgcraft-python)
[![pypi](https://img.shields.io/pypi/v/pkgcraft.svg)](https://pypi.python.org/pypi/pkgcraft)

# pkgcraft-python

Python bindings for [pkgcraft](https://github.com/pkgcraft/pkgcraft).

## Install

Install pre-built package from pypi:

    pip install pkgcraft

Install from git (assumes pkgcraft-c has been installed from git and cython is
available):

    pip install https://github.com/pkgcraft/pkgcraft-python/archive/master.tar.gz

Install from a tarball (assumes required release of pkgcraft-c is installed):

    python setup.py install

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
```

For development purposes, testing is performed under tox using varying targets
for different functions. Use `tox list` to see all the target descriptions.
