import pytest

from pkgcraft.config import Config
from pkgcraft.error import PkgcraftError
from pkgcraft.repo import EbuildRepo


class TestEbuildRepo:

    def test_init(self):
        with pytest.raises(PkgcraftError, match=f"doesn't support regular creation"):
            EbuildRepo()

    def test_category_dirs(self, repo):
        path = repo.path
        config = Config()
        r = config.add_repo(path)

        # empty repo
        assert r.category_dirs == ()

        # create ebuild
        repo.create_ebuild("cat1/pkga-1")
        assert r.category_dirs == ('cat1',)

        # create new ebuild version
        repo.create_ebuild("cat1/pkga-2")
        assert r.category_dirs == ('cat1',)

        # create new pkg
        repo.create_ebuild("cat1/pkgb-1")
        assert r.category_dirs == ('cat1',)

        # create new pkg in new category
        repo.create_ebuild("cat2/pkga-1")
        assert r.category_dirs == ('cat1', 'cat2')
