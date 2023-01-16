import binascii
import os
import textwrap
from collections.abc import MutableSet
from datetime import datetime
from pathlib import Path

import pytest

from pkgcraft.atom import Cpv
from pkgcraft.config import Config
from pkgcraft.eapi import EAPI_LATEST
from pkgcraft.repo import EbuildRepo, FakeRepo


class _FileSet(MutableSet):
    """Set object that maps to file content updates for a given path."""

    def __init__(self, path):
        self._path = path
        self._set = set()

    def _sync(self):
        with open(self._path, 'w') as f:
            f.write('\n'.join(self._set) + '\n')

    def __contains__(self, key):
        return key in self._set

    def __iter__(self):
        return iter(self._set)

    def __len__(self):
        return len(self._set)

    def update(self, iterable):
        orig_entries = len(self._set)
        self._set.update(iterable)
        if len(self._set) != orig_entries:
            self._sync()

    def add(self, value):
        orig_entries = len(self._set)
        self._set.add(value)
        if len(self._set) != orig_entries:
            self._sync()

    def remove(self, value):
        orig_entries = len(self._set)
        self._set.remove(value)
        if len(self._set) != orig_entries:
            self._sync()

    def discard(self, value):
        orig_entries = len(self._set)
        self._set.discard(value)
        if len(self._set) != orig_entries:
            self._sync()


class TempRawEbuildRepo:
    """Class for creating and manipulating raw ebuild repos."""

    def __init__(self, path, id='fake', eapi=EAPI_LATEST, masters=(), arches=()):
        self._path = Path(path)
        self._repo_id = id
        self._arches = _FileSet(self._path / 'profiles' / 'arch.list')
        self._today = datetime.today()
        try:
            os.makedirs(self._path / 'profiles')
            with open(self._path / 'profiles' / 'repo_name', 'w') as f:
                f.write(f'{self._repo_id}\n')
            with open(self._path / 'profiles' / 'eapi', 'w') as f:
                f.write(f'{eapi}\n')
            os.makedirs(self._path / 'metadata')
            with open(self._path / 'metadata' / 'layout.conf', 'w') as f:
                f.write(textwrap.dedent(f"""\
                    masters = {' '.join(map(str, masters))}
                    cache-formats =
                    thin-manifests = true
                """))
            if arches:
                self._arches.update(arches)
            os.makedirs(self._path / 'eclass')
        except FileExistsError:
            pass

    @property
    def path(self):
        return self._path

    def create_profiles(self, profiles):
        for p in profiles:
            os.makedirs(self._path / 'profiles' / p.path, exist_ok=True)
            with open(self._path / 'profiles' / 'profiles.desc', 'a+') as f:
                f.write(f'{p.arch} {p.path} {p.status}\n')
            if p.deprecated:
                with open(self._path / 'profiles' / p.path / 'deprecated', 'w') as f:
                    f.write("# deprecated\ndeprecation reason\n")
            with open(self._path / 'profiles' / p.path / 'make.defaults', 'w') as f:
                if p.defaults is not None:
                    f.write('\n'.join(p.defaults))
                else:
                    f.write(f'ARCH={p.arch}\n')
            if p.eapi:
                with open(self._path / 'profiles' / p.path / 'eapi', 'w') as f:
                    f.write(f'{p.eapi}\n')

    def create_ebuild(self, cpv='cat/pkg-1', data=None, **kwargs):
        """Create an ebuild for a given CPV."""
        cpv = Cpv(cpv)
        ebuild_dir = self._path / cpv.category / cpv.package
        os.makedirs(ebuild_dir, exist_ok=True)

        # use defaults for some ebuild metadata if unset
        eapi = kwargs.pop('eapi', EAPI_LATEST)
        slot = kwargs.pop('slot', '0')
        desc = kwargs.pop('description', 'stub package description')

        ebuild_path = ebuild_dir / f'{cpv.package}-{cpv.version}.ebuild'
        with open(ebuild_path, 'w') as f:
            if self._repo_id == 'gentoo':
                f.write(textwrap.dedent(f"""\
                    # Copyright 1999-{self._today.year} Gentoo Authors
                    # Distributed under the terms of the GNU General Public License v2
                """))
            f.write(f'EAPI="{eapi}"\n')
            f.write(f'DESCRIPTION="{desc}"\n')
            f.write(f'SLOT="{slot}"\n')

            if license := kwargs.get('license'):
                f.write(f'LICENSE="{license}"\n')
                # create a fake license
                os.makedirs(self._path / 'licenses', exist_ok=True)
                open(self._path / 'licenses' / license, mode='w').close()

            for k, v in kwargs.items():
                # handle sequences such as KEYWORDS and IUSE
                if isinstance(v, (tuple, list)):
                    v = ' '.join(v)
                f.write(f'{k.upper()}="{v}"\n')
            if data:
                f.write(data.strip() + '\n')

        return ebuild_path


class TempEbuildRepo(TempRawEbuildRepo, EbuildRepo):
    """Class for creating and manipulating ebuild repos."""

    def __init__(self, path, id='fake', priority=0, **kwargs):
        TempRawEbuildRepo.__init__(self, path, id, **kwargs)
        EbuildRepo.__init__(self, self.path, id, priority)

    def create_pkg(self, cpv, *args, **kwargs):
        """Create an ebuild for a given CPV and return the related package object."""
        self.create_ebuild(cpv, *args, **kwargs)
        return next(iter(self.iter_restrict(cpv)))


@pytest.fixture(scope="function")
def config():
    """Function-scoped config object."""
    return Config()


@pytest.fixture
def raw_ebuild_repo(tmp_path_factory):
    """Create a generic ebuild repository."""
    return TempRawEbuildRepo(str(tmp_path_factory.mktemp('repo')))


@pytest.fixture
def make_raw_ebuild_repo(tmp_path_factory):
    """Factory for ebuild repo creation."""
    def _make_repo(path=None, **kwargs):
        path = str(tmp_path_factory.mktemp('repo')) if path is None else path
        return TempRawEbuildRepo(path, **kwargs)
    return _make_repo


@pytest.fixture
def ebuild_repo(tmp_path_factory):
    """Create a generic ebuild repository."""
    return TempEbuildRepo(str(tmp_path_factory.mktemp('repo')))


class TempFakeRepo(FakeRepo):
    """Class for creating and manipulating fake repos."""

    def create_pkg(self, cpv):
        """Insert a given CPV and return the related package object."""
        self.extend([cpv])
        return next(iter(self.iter_restrict(cpv)))


@pytest.fixture
def fake_repo():
    """Create a generic ebuild repository."""
    return TempFakeRepo()


@pytest.fixture
def random_str():
    """Factory for random string generation."""
    def _make_str(length=10):
        return binascii.b2a_hex(os.urandom(length)).decode()
    return _make_str


@pytest.fixture
def letters():
    """Return a lexically incrementing string."""
    l = []
    def _letters():
        nonlocal l
        if not l or l[-1] == 'z':
            l.append('a')
        else:
            char = chr(ord(l.pop()) + 1)
            l.append(char)
        return ''.join(l)
    return _letters


@pytest.fixture
def make_ebuild_repo(tmp_path_factory, letters):
    """Factory for ebuild repo creation."""
    def _make_repo(path=None, id=None, priority=0, config=None, **kwargs):
        path = str(tmp_path_factory.mktemp('repo')) if path is None else path
        id = id if id is not None else letters()
        r = TempEbuildRepo(path, id, priority, **kwargs)
        if config is not None:
            config.add_repo(r)
        return r
    return _make_repo


@pytest.fixture
def make_fake_repo(letters):
    """Factory for ebuild repo creation."""
    def _make_repo(cpvs_or_path=None, id=None, priority=0, config=None):
        cpvs_or_path = cpvs_or_path if cpvs_or_path is not None else ()
        id = id if id is not None else letters()
        r = TempFakeRepo(cpvs_or_path, id, priority)
        if config is not None:
            config.add_repo(r)
        return r
    return _make_repo
