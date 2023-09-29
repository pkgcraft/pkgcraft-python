import glob
import os
import subprocess
from multiprocessing import cpu_count

from Cython.Build import cythonize
from Cython.Compiler import Options
from setuptools import setup
from setuptools.command import build_ext as dst_build_ext
from setuptools.extension import Extension

MODULEDIR = "src/pkgcraft"
PACKAGEDIR = os.path.dirname(MODULEDIR)

# version requirements for pkgcraft C library
MIN_VERSION = "0.0.12"
MAX_VERSION = "0.0.12"


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
        "-I": "include_dirs",
        "-L": "library_dirs",
        "-l": "libraries",
    }

    try:
        tokens = subprocess.check_output(
            ["pkg-config", "--libs", "--cflags"] + list(packages)
        ).split()
    except subprocess.CalledProcessError:
        raise SystemExit(f"running pkg-config failed")

    for token in tokens:
        token = token.decode()
        if token[:2] in flag_map:
            kw.setdefault(flag_map.get(token[:2]), []).append(token[2:])
        else:
            kw.setdefault("extra_compile_args", []).append(token)
    return kw


def extensions(**build_opts):
    """Register cython extensions to be built."""
    if not build_opts:
        build_opts = {"depends": [], "include_dirs": []}
    exts = []

    for ext in glob.glob(f"{MODULEDIR}/**/*.pyx", recursive=True):
        # strip package dir
        module = ext.rpartition(PACKAGEDIR)[-1].lstrip(os.path.sep)
        # strip file extension and translate to module namespace
        module = os.path.splitext(module)[0].replace(os.path.sep, ".")
        exts.append(Extension(name=module, sources=[ext], **build_opts))

    return exts


class build_ext(dst_build_ext.build_ext):
    """Enable building cython extensions with coverage support."""

    user_options = dst_build_ext.build_ext.user_options + [
        ("cython-coverage", None, "enable cython coverage support"),
        ("develop", None, "convert cythonize and compile-time warnings into errors"),
        ("doc", None, "support API doc generation"),
    ]

    def initialize_options(self):
        self.cython_coverage = False
        self.develop = False
        self.doc = False
        super().initialize_options()

    def finalize_options(self):
        self.cython_coverage = bool(self.cython_coverage)
        self.develop = bool(self.develop)
        self.doc = bool(self.doc)

        # default to parallelizing build across all cores
        if self.parallel is None:
            self.parallel = cpu_count()

        super().finalize_options()

    def run(self):
        # default cython compiler directives
        compiler_directives = {"language_level": 3}

        if self.cython_coverage:
            compiler_directives["linetrace"] = True
            trace_macros = [("CYTHON_TRACE", "1"), ("CYTHON_TRACE_NOGIL", "1")]
            for ext in self.extensions:
                ext.define_macros.extend(trace_macros)

        if self.develop:
            Options.warning_errors = True
            os.environ["CFLAGS"] = os.environ.get("CFLAGS", "") + " -Werror"

        if self.doc:
            compiler_directives["binding"] = True
            compiler_directives["embedsignature"] = True

        # generate C modules with cython
        self.extensions[:] = cythonize(
            self.extensions,
            force=True,
            compiler_directives=compiler_directives,
            annotate=False,
        )

        # HACK: Force setuptools to reinject its private attributes to
        # extension objects that were overridden by `cythonize`, otherwise the
        # build fails when it tries to access them.
        build_ext = self.reinitialize_command("build_ext")
        build_ext.ensure_finalized()

        # delay pkg-config to avoid requiring library during sdist
        pkgcraft_opts = pkg_config("pkgcraft")

        try:
            p = subprocess.run(
                ["pkg-config", "--modversion", "pkgcraft"],
                capture_output=True,
                check=True,
                text=True,
            )
            version = p.stdout.strip()
        except subprocess.CalledProcessError:
            raise SystemExit("failed retrieving pkgcraft C library version")

        try:
            subprocess.check_output(["pkg-config", "--atleast-version", MIN_VERSION, "pkgcraft"])
        except subprocess.CalledProcessError:
            raise SystemExit(f"pkgcraft C library {version} fails requirements >={MIN_VERSION}")

        try:
            subprocess.check_output(["pkg-config", "--max-version", MAX_VERSION, "pkgcraft"])
        except subprocess.CalledProcessError:
            raise SystemExit(f"pkgcraft C library {version} fails requirements <={MAX_VERSION}")

        for ext in self.extensions:
            for attr, data in pkgcraft_opts.items():
                getattr(ext, attr).extend(data)

        print(f"Building against pkgcraft-c-{version}")
        super().run()


def exclude_cython_files():
    """Generate package data exclusion mapping to avoid installing cython files."""
    excluded = ["*.pxd", "*.pyx", "*.c"]
    excludes = {}

    for root, dirs, _files in os.walk("src"):
        for d in dirs:
            path = os.path.join(root, d).lstrip("src/")
            module = path.replace(os.path.sep, ".")
            excludes[module] = excluded

    return excludes


setup(
    ext_modules=extensions(),
    cmdclass={
        "build_ext": build_ext,
    },
    exclude_package_data=exclude_cython_files(),
)
