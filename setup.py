import os
import subprocess
import sys

from setuptools import setup
from setuptools.command import sdist as dst_sdist
from setuptools.extension import Extension

MODULEDIR = 'src/pkgcraft'
PACKAGEDIR = os.path.dirname(MODULEDIR)

def pkg_config(*packages, **kw):
    """Translate pkg-config data to compatible Extension parameters.

    Example usage:

    >>> from setuptools.extension import Extension
    >>>
    >>> ext_kwargs = dict(
    ...     include_dirs=['include'],
    ...     extra_compile_args=['-std=c++11'],
    ... )
    >>> extensions = [
    ...     Extension('foo', ['foo.c']),
    ...     Extension('bar', ['bar.c'], **pkg_config('lcms2')),
    ...     Extension('ext', ['ext.cpp'], **pkg_config(('nss', 'libusb-1.0'), **ext_kwargs)),
    ... ]
    """
    flag_map = {
        '-I': 'include_dirs',
        '-L': 'library_dirs',
        '-l': 'libraries',
    }

    try:
        tokens = subprocess.check_output(
            ['pkg-config', '--libs', '--cflags'] + list(packages)).split()
    except OSError as e:
        sys.stderr.write(f'running pkg-config failed: {e.strerror}\n')
        sys.exit(1)

    for token in tokens:
        token = token.decode()
        if token[:2] in flag_map:
            kw.setdefault(flag_map.get(token[:2]), []).append(token[2:])
        else:
            kw.setdefault('extra_compile_args', []).append(token)
    return kw


def cython_pyx(path=MODULEDIR):
    """Return all available cython extensions under a given path."""
    for root, _dirs, files in os.walk(path):
        for f in files:
            if f.endswith('.pyx'):
                yield str(os.path.join(root, f))


def cython_exts(path=MODULEDIR, build_opts=None):
    """Prepare all cython extensions under a given path to be built."""
    if build_opts is None:
        build_opts = {'depends': [], 'include_dirs': []}
    exts = []

    for ext in cython_pyx(path):
        cythonized = os.path.splitext(ext)[0] + '.c'
        if os.path.exists(cythonized):
            ext_path = cythonized
        else:
            ext_path = ext

        # strip package dir
        module = ext_path.rpartition(PACKAGEDIR)[-1].lstrip(os.path.sep)
        # strip file extension and translate to module namespace
        module = os.path.splitext(module)[0].replace(os.path.sep, '.')
        exts.append(Extension(module, [ext_path], **build_opts))

    return exts


class sdist(dst_sdist.sdist):
    """sdist command wrapper to bundle generated files for release."""

    def run(self):
        # generate cython extensions
        extensions = list(cython_pyx())
        if extensions:
            from Cython.Build import cythonize
            cythonize(extensions)

        super().run()


setup(
    ext_modules=cython_exts(build_opts=pkg_config('pkgcraft')),
    cmdclass={'sdist': sdist},
)
