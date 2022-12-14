from . cimport pkgcraft_c as C


def _get_last_error():
    """Get the last pkgcraft-c error that occurred."""
    err = C.pkgcraft_error_last()
    if err is NULL:
        raise RuntimeError('no pkgcraft-c error occurred')

    msg = err.message.decode()
    kind = err.kind
    C.pkgcraft_error_free(err)

    return msg, kind


def _raise_last_error():
    """Raise the last pkgcraft-c error that occurred, automatically determining the type."""
    msg, kind = _get_last_error()
    raise _PkgcraftError.types[kind](msg)


class _PkgcraftError(Exception):

    # map of error kinds to classes
    types = {}

    @classmethod
    def __init_subclass__(cls, **kwargs):
        for kind in cls.kinds:
            setting = cls.types.setdefault(kind, cls)
            if setting is not cls:
                name, existing = cls.__name__, setting.__name__
                raise RuntimeError(f'{name}: error kind {kind} already registered to {existing}')
        super().__init_subclass__(**kwargs)


class PkgcraftError(_PkgcraftError):
    """Generic pkgcraft exception."""

    kinds = (C.ErrorKind.ERROR_KIND_GENERIC, C.ERROR_KIND_PKGCRAFT)

    def __init__(self, str msg=None):
        if msg is not None:
            super().__init__(msg)
        else:
            msg, kind = _get_last_error()
            if kind is not C.ErrorKind.ERROR_KIND_PKGCRAFT and kind not in self.kinds:
                err_type = self.__class__.__name__
                raise RuntimeError(f"{err_type} doesn't handle error kind: {kind}")
            super().__init__(msg)


class ConfigError(PkgcraftError):
    """Generic configuration exception."""
    kinds = (C.ErrorKind.ERROR_KIND_CONFIG,)


class InvalidRepo(PkgcraftError):
    """Repo doesn't meet required specifications."""
    kinds = (C.ErrorKind.ERROR_KIND_REPO,)


class InvalidCpv(PkgcraftError, ValueError):
    """Package CPV doesn't meet required specifications."""
    kinds = ()


class InvalidAtom(PkgcraftError, ValueError):
    """Package atom doesn't meet required specifications."""
    kinds = ()


class InvalidVersion(PkgcraftError, ValueError):
    """Atom version doesn't meet required specifications."""
    kinds = ()


class InvalidRestrict(PkgcraftError, ValueError):
    """Object cannot be converted to a restriction."""
    kinds = ()


class IndirectInit(TypeError):
    """Object cannot be created directly via __init__()."""

    def __init__(self, obj):
        obj_name = obj.__class__.__name__
        super().__init__(f"{obj_name} objects cannot be created directly via __init__()")
