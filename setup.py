import copy
import os
import subprocess
import sys
from multiprocessing import cpu_count

from setuptools import setup
from setuptools.command import build_ext as dst_build_ext, sdist as dst_sdist
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
        build_ext = self.reinitialize_command('build_ext')
        build_ext.ensure_finalized()

        # generate cython extensions if any exist
        extensions = list(cython_pyx())
        if extensions:
            from Cython.Build import cythonize
            cythonize(extensions, nthreads=cpu_count())

        super().run()


class build_ext(dst_build_ext.build_ext):
    """Build native extensions."""

    user_options = dst_build_ext.build_ext.user_options + [
        ("disable-distutils-flag-fixing", None,
         "disable fixing of issue 969718 in python, adding missing -fno-strict-aliasing"),
    ]

    def initialize_options(self):
        super().initialize_options()
        self.disable_distutils_flag_fixing = False
        self.default_header_install_dir = None

    def finalize_options(self):
        super().finalize_options()
        # add header install dir to the search path
        # (fixes virtualenv builds for consumer extensions)
        self.set_undefined_options(
            'install',
            ('install_headers', 'default_header_install_dir'))
        if self.default_header_install_dir:
            self.default_header_install_dir = os.path.dirname(self.default_header_install_dir)
            for e in self.extensions:
                # include_dirs may actually be shared between multiple extensions
                if self.default_header_install_dir not in e.include_dirs:
                    e.include_dirs.append(self.default_header_install_dir)

    @staticmethod
    def determine_ext_lang(ext_path):
        """Determine file extensions for generated cython extensions."""
        with open(ext_path) as f:
            for line in f:
                line = line.lstrip()
                if not line:
                    continue
                elif line[0] != '#':
                    return None
                line = line[1:].lstrip()
                if line[:10] == 'distutils:':
                    key, _, value = [s.strip() for s in line[10:].partition('=')]
                    if key == 'language':
                        return value
            else:
                return None

    def no_cythonize(self):
        """Determine file paths for generated cython extensions."""
        extensions = copy.deepcopy(self.extensions)
        for extension in extensions:
            sources = []
            for sfile in extension.sources:
                path, ext = os.path.splitext(sfile)
                if ext in ('.pyx', '.py'):
                    lang = build_ext.determine_ext_lang(sfile)
                    if lang == 'c++':
                        ext = '.cpp'
                    else:
                        ext = '.c'
                    sfile = path + ext
                sources.append(sfile)
            extension.sources[:] = sources
        return extensions

    def run(self):
        # ensure that the platform checks were performed
        self.run_command('config')

        # only regenerate cython extensions if requested or required
        use_cython = (
            os.environ.get('USE_CYTHON', False) or
            any(not os.path.exists(x) for ext in self.no_cythonize() for x in ext.sources))
        if use_cython:
            from Cython.Build import cythonize
            cythonize(self.extensions, nthreads=cpu_count())

        self.extensions = self.no_cythonize()
        super().run()

    def build_extensions(self):
        for x in ("compiler_so", "compiler", "compiler_cxx"):
            if self.debug:
                l = [y for y in getattr(self.compiler, x) if y != '-DNDEBUG']
                l.append('-Wall')
                setattr(self.compiler, x, l)
            if not self.disable_distutils_flag_fixing:
                val = getattr(self.compiler, x)
                if "-fno-strict-aliasing" not in val:
                    val.append("-fno-strict-aliasing")
            if getattr(self.distribution, 'check_defines', None):
                val = getattr(self.compiler, x)
                for d, result in self.distribution.check_defines.items():
                    if result:
                        val.append(f'-D{d}=1')
                    else:
                        val.append(f'-U{d}')
        super().build_extensions()


setup(
    ext_modules=cython_exts(build_opts=pkg_config('pkgcraft')),
    zip_safe=False,
    cmdclass={
        'sdist': sdist,
    }
)
