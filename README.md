[![CI](https://github.com/pkgcraft/pkgcraft-python/workflows/CI/badge.svg)](https://github.com/pkgcraft/pkgcraft-python/actions/workflows/ci.yml)

# pkgcraft-python

Python bindings for pkgcraft.

## Development

Requirements: >=rust-1.59, >=python-3.8, and [tox](https://pypi.org/project/tox/)

For development purposes, it's easiest to build and test using tox:

```bash
git clone --recurse-submodules https://github.com/pkgcraft/scallop.git
git clone https://github.com/pkgcraft/pkgcraft.git
git clone https://github.com/pkgcraft/pkgcraft-python.git

cd pkgcraft-python
# build and test
tox -e python
# benchmark
tox -e bench
```
