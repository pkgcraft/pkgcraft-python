from importlib.metadata import version as _version, PackageNotFoundError as _PackageNotFoundError

try:
    __version__ = _version('pkgcraft')
except _PackageNotFoundError:
    # package is not installed
    pass
