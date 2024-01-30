from . cimport C


cdef tuple get_last_error():
    """Get the last pkgcraft error that occurred."""
    if err := C.pkgcraft_error_last():
        msg, kind = err.message.decode(), err.kind
        C.pkgcraft_error_free(err)
        return msg, kind
    raise RuntimeError('no pkgcraft error occurred')


class _PkgcraftError:

    # map of error kinds to classes
    types = {}

    @classmethod
    def __init_subclass__(cls, **kwargs):
        for kind in cls._kinds:
            setting = cls.types.setdefault(kind, cls)
            if setting is not cls:
                name, existing = cls.__name__, setting.__name__
                raise RuntimeError(f'{name}: error kind {kind} already registered to {existing}')
        super().__init_subclass__(**kwargs)


class PkgcraftError(_PkgcraftError, Exception):
    """Generic pkgcraft exception."""

    _kinds = (C.ERROR_KIND_GENERIC, C.ERROR_KIND_PKGCRAFT)

    def __new__(cls, msg=None, **kwargs):
        if msg is not None:
            inst = super().__new__(cls)
        else:
            # If no message is specified, pull the last error that occurred,
            # automatically determining the subclass for PkgcraftError.
            msg, kind = get_last_error()
            err_cls = cls.types[kind]
            # only the generic PkgcraftError class is allowed to alter its type
            if (cls is not PkgcraftError and
                    kind != C.ERROR_KIND_PKGCRAFT and
                    kind not in cls._kinds):  # pragma: no cover
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
    _kinds = (C.ERROR_KIND_CONFIG,)


class InvalidRepo(PkgcraftError):
    """Repo doesn't meet required specifications."""
    _kinds = (C.ERROR_KIND_REPO,)


class InvalidPkg(PkgcraftError):
    """Package doesn't meet required specifications."""
    _kinds = (C.ERROR_KIND_PKG,)


class InvalidCpn(PkgcraftError, ValueError):
    """Cpn doesn't meet required specifications."""
    _kinds = ()


class InvalidCpv(PkgcraftError, ValueError):
    """Cpv doesn't meet required specifications."""
    _kinds = ()


class InvalidDep(PkgcraftError, ValueError):
    """Package dependency doesn't meet required specifications."""
    _kinds = ()


class InvalidVersion(PkgcraftError, ValueError):
    """Package version doesn't meet required specifications."""
    _kinds = ()


class InvalidRestrict(PkgcraftError, ValueError):
    """Object cannot be converted to a restriction."""
    _kinds = ()


class IndirectType(TypeError):
    """Object type instances cannot be directly created."""


cdef class Indirect:
    """Instances cannot be directly created."""

    def __init__(self, *args, **kwargs):
        obj_name = self.__class__.__name__
        raise IndirectType(f"{obj_name} instances cannot be directly created")
