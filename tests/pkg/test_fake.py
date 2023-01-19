import pytest

from .base import BasePkgTests


@pytest.fixture
def make_repo(make_fake_repo):
    return make_fake_repo


@pytest.fixture
def repo(make_fake_repo):
    return make_fake_repo(id="fake")


@pytest.fixture
def pkg(repo):
    return repo.create_pkg("cat/pkg-1")


class TestFakePkg(BasePkgTests):
    """Run FakePkg tests."""
