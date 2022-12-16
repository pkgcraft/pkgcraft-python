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


class _PkgcraftError(Exception):

    # map of error kinds to classes
    types = {}

    @classmethod
    def __init_subclass__(cls, **kwargs):
        for kind in cls.kinds:
            setting = cls.types.setdefault(kind, cls)
            if setting is not cls:  # pragma: no cover
                name, existing = cls.__name__, setting.__name__
                raise RuntimeError(f'{name}: error kind {kind} already registered to {existing}')
        super().__init_subclass__(**kwargs)


class PkgcraftError(_PkgcraftError):
    """Generic pkgcraft exception."""

    kinds = (C.ERROR_KIND_GENERIC, C.ERROR_KIND_PKGCRAFT)

    def __new__(cls, msg=None, **kwargs):
        if msg is not None:
            inst = super().__new__(cls)
        else:
            # If no specific message is passed, pull the last pkgcraft-c error
            # that occurred, automatically determining the subclass for PkgcraftError.
            msg, kind = _get_last_error()
            err_cls = cls.types[kind]
            # only the generic PkgcraftError class is allowed to alter its type
            if (cls is not PkgcraftError and
                    kind != C.ERROR_KIND_PKGCRAFT and
                    kind not in cls.kinds):  # pragma: no cover
                raise RuntimeError(f"{cls.__name__} doesn't handle error kind: {kind}")
            if err_cls is not PkgcraftError:
                inst = super().__new__(err_cls)
            else:
                inst = super().__new__(cls)

        inst.msg = msg
        return inst

    def __init__(self, *args):
        super().__init__(self.msg)


class ConfigError(PkgcraftError):
    """Generic configuration exception."""
    kinds = (C.ERROR_KIND_CONFIG,)


class InvalidRepo(PkgcraftError):
    """Repo doesn't meet required specifications."""
    kinds = (C.ERROR_KIND_REPO,)


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
