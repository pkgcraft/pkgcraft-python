|CI| |coverage| |pypi|

===============
pkgcraft-python
===============

Python bindings for pkgcraft_.

Install
=======

Install pre-built package from pypi::

    pip install pkgcraft

Install from git (assumes pkgcraft-c has been installed from git and cython is
available)::

    pip install https://github.com/pkgcraft/pkgcraft-python/archive/master.tar.gz

Install from a tarball (assumes required release of pkgcraft-c is installed)::

    python setup.py install

Development
===========

Requirements: tox_ and pkgcraft-c_

For development purposes, testing is performed under tox with varying targets
for different functions, e.g. ``tox -e valgrind`` runs tests while checking for
memory leaks using valgrind_. Use **tox list** to see all the target
descriptions.

.. _tox: https://pypi.org/project/tox/
.. _valgrind: https://valgrind.org/
.. _pkgcraft: https://github.com/pkgcraft/pkgcraft
.. _pkgcraft-c: https://github.com/pkgcraft/pkgcraft-c

.. |CI| image:: https://github.com/pkgcraft/pkgcraft-python/workflows/CI/badge.svg
   :target: https://github.com/pkgcraft/pkgcraft-python/actions/workflows/ci.yml
.. |coverage| image:: https://codecov.io/gh/pkgcraft/pkgcraft-python/branch/main/graph/badge.svg
   :target: https://codecov.io/gh/pkgcraft/pkgcraft-python
.. |pypi| image:: https://img.shields.io/pypi/v/pkgcraft.svg
   :target: https://pypi.python.org/pypi/pkgcraft
