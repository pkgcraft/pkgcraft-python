import os
import subprocess
import sys

from setuptools import setup
from setuptools.command import build_ext as dst_build_ext
from setuptools.command import sdist as dst_sdist
from setuptools.extension import Extension

MODULEDIR = 'src/pkgcraft'
PACKAGEDIR = os.path.dirname(MODULEDIR)
# running against git repo
GIT = os.path.exists(os.path.join(os.path.dirname(__file__), '.git'))

compiler_directives = {'language_level': 3}


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


def extensions(**build_opts):
    """Register cython extensions to be built."""
    if not build_opts:
        build_opts = {'depends': [], 'include_dirs': []}
    exts = []

    for ext in CYTHON_EXTS:
        cythonized = os.path.splitext(ext)[0] + '.c'
        # use pre-generated modules for releases
        if not GIT and os.path.exists(cythonized):
            ext_path = cythonized
        else:
            ext_path = ext

        # strip package dir
        module = ext_path.rpartition(PACKAGEDIR)[-1].lstrip(os.path.sep)
        # strip file extension and translate to module namespace
        module = os.path.splitext(module)[0].replace(os.path.sep, '.')
        exts.append(Extension(name=module, sources=[ext_path], **build_opts))

    return exts


class sdist(dst_sdist.sdist):
    """sdist command wrapper to bundle generated files for release."""

    def run(self):
        # generate cython extensions
        if CYTHON_EXTS:
            from Cython.Build import cythonize
            cythonize(
                CYTHON_EXTS,
                compiler_directives=compiler_directives,
                annotate=False,
            )

        super().run()


class build_ext(dst_build_ext.build_ext):
    """Enable building cython extensions with coverage support."""

    user_options = dst_build_ext.build_ext.user_options + [
        ("cython-coverage", None, "enable cython coverage support")]

    def initialize_options(self):
        self.cython_coverage = False
        super().initialize_options()

    def finalize_options(self):
        self.cython_coverage = bool(self.cython_coverage)

        if GIT:
            ext_modules = self.distribution.ext_modules[:]

            # optionally enable coverage support for cython modules
            if self.cython_coverage:
                compiler_directives['linetrace'] = True
                trace_macros = [('CYTHON_TRACE', '1'), ('CYTHON_TRACE_NOGIL', '1')]
                for ext in ext_modules:
                    ext.define_macros.extend(trace_macros)

            from Cython.Build import cythonize
            self.distribution.ext_modules[:] = cythonize(
                ext_modules,
                compiler_directives=compiler_directives,
                annotate=False,
            )

        super().finalize_options()

    def run(self):
        # delay pkg-config to avoid requiring library during sdist
        pkgcraft_opts = pkg_config('pkgcraft')
        for ext in self.extensions:
            for attr, data in pkgcraft_opts.items():
                getattr(ext, attr).extend(data)

        super().run()


CYTHON_EXTS = list(cython_pyx(MODULEDIR))

setup(
    ext_modules=extensions(),
    entry_points={'pytest11': ['pkgcraft = pkgcraft._pytest']},
    cmdclass={
        'build_ext': build_ext,
        'sdist': sdist,
    },
)
