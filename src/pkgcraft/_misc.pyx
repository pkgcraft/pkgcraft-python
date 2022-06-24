from collections.abc import Mapping
from operator import itemgetter

SENTINEL = object()


class ImmutableDict(Mapping):
    """Immutable dict, unchangeable after instantiation.

    Because it's immutable, it's hashable.
    """

    def __init__(self, data=None):
        if isinstance(data, ImmutableDict):
            mapping = data._dict
        elif isinstance(data, Mapping):
            mapping = data
        elif data is None:
            mapping = {}
        else:
            try:
                mapping = {k: v for k, v in data}
            except TypeError as e:
                raise TypeError(f'unsupported data format: {e}')
        object.__setattr__(self, '_dict', mapping)

    def __getitem__(self, key):
        # hack to avoid recursion exceptions for subclasses that use
        # inject_getitem_as_getattr()
        if key == '_dict':
            return object.__getattribute__(self, '_dict')
        return self._dict[key]

    def __iter__(self):
        return iter(self._dict)

    def __reversed__(self):
        return reversed(self._dict)

    def __len__(self):
        return len(self._dict)

    def __repr__(self):
        return str(self._dict)

    def __str__(self):
        return str(self._dict)

    def __hash__(self):
        return hash(tuple(sorted(self._dict.items(), key=itemgetter(0))))
