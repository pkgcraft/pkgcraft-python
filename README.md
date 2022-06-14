[![CI](https://github.com/pkgcraft/pkgcraft-python/workflows/CI/badge.svg)](https://github.com/pkgcraft/pkgcraft-python/actions/workflows/ci.yml)

# pkgcraft-python

Python bindings for pkgcraft.

## Development

Requirements: >=python-3.9 and [tox](https://pypi.org/project/tox/)

Use the following commands to set up a Linux dev environment:

```bash
git clone --recurse-submodules https://github.com/pkgcraft/scallop.git
git clone https://github.com/pkgcraft/pkgcraft.git
git clone https://github.com/pkgcraft/pkgcraft-c.git
git clone https://github.com/pkgcraft/pkgcraft-python.git

# install cargo-c
cargo install cargo-c

# build pkgcraft-c library
cd pkgcraft-python
cargo cinstall --prefix="${PWD}/pkgcraft" --pkgconfigdir="${PWD}/pkgcraft" --manifest-path=../pkgcraft-c/Cargo.toml
export PKG_CONFIG_PATH="${PWD}/pkgcraft"
export LD_LIBRARY_PATH="${PWD}/pkgcraft/lib"

# build and test
tox -e python
# benchmark
tox -e bench
```
