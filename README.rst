|ci| |coverage| |pypi|

===============
pkgcraft-python
===============

Python bindings for pkgcraft_.

Install
=======

Install wheel from PyPI (comes with bundled pkgcraft-c_ library)::

    pip install pkgcraft

Install from git (assumes pkgcraft-c_ from git is installed)::

    git clone --recurse-submodules https://github.com/pkgcraft/pkgcraft-python.git
    pip install pkgcraft-python

Development
===========

Requirements: tox_ and pkgcraft-c_

For development purposes, testing is performed under tox with varying targets
for different functions, e.g. ``tox -e valgrind`` runs tests while checking for
memory leaks using valgrind_. Use ``tox list`` to see all the target
descriptions.

.. _tox: https://pypi.org/project/tox/
.. _valgrind: https://valgrind.org/
.. _pkgcraft: https://github.com/pkgcraft/pkgcraft/tree/main/crates/pkgcraft
.. _pkgcraft-c: https://github.com/pkgcraft/pkgcraft/tree/main/crates/pkgcraft-c

.. |ci| image:: https://github.com/pkgcraft/pkgcraft-python/workflows/ci/badge.svg
   :target: https://github.com/pkgcraft/pkgcraft-python/actions/workflows/ci.yml
.. |coverage| image:: https://codecov.io/gh/pkgcraft/pkgcraft-python/branch/main/graph/badge.svg
   :target: https://codecov.io/gh/pkgcraft/pkgcraft-python
.. |pypi| image:: https://img.shields.io/pypi/v/pkgcraft.svg
   :target: https://pypi.python.org/pypi/pkgcraft
