[![CI](https://github.com/pkgcraft/pkgcraft-python/workflows/CI/badge.svg)](https://github.com/pkgcraft/pkgcraft-python/actions/workflows/ci.yml)

# pkgcraft-python

Python bindings for pkgcraft.

## Development

Requirements: >=python-3.9, [tox](https://pypi.org/project/tox/), and
everything required to build
[pkgcraft-c](https://github.com/pkgcraft/pkgcraft-c)

Use the following commands to set up a Linux dev environment:

```bash
# clone the pkgcraft workspace
git clone --recursive-submodules https://github.com/pkgcraft/pkgcraft-workspace.git

# build pkgcraft-c library and set shell variables (e.g. $PKG_CONFIG_PATH)
cd pkgcraft-workspace
source ./build-c-lib

cd pkgcraft-python
# build and test
tox -e python
# benchmark
tox -e bench
```
