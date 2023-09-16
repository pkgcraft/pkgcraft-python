import os
import shutil
from pathlib import Path

import pytest

from pkgcraft.eapi import EAPI_LATEST_OFFICIAL
from pkgcraft.error import InvalidRepo
from pkgcraft.repo import EbuildRepo, Repo

from .base import BaseRepoTests


@pytest.fixture
def make_repo(make_ebuild_repo):
    return make_ebuild_repo


@pytest.fixture
def repo(ebuild_repo):
    return ebuild_repo


class TestEbuildRepo(BaseRepoTests):
    def test_init(self, make_raw_ebuild_repo):
        # nonexistent path
        with pytest.raises(InvalidRepo):
            EbuildRepo("/path/to/nonexistent/repo")

        # overlays must be initialized via Config.add_repo()
        repo = make_raw_ebuild_repo(masters=["nonexistent"])
        with pytest.raises(InvalidRepo, match="overlay must be added via config"):
            EbuildRepo(repo.path)

        repo = make_raw_ebuild_repo()
        path = repo.path

        # empty repo
        r = EbuildRepo(path)
        assert len(r) == 0

        # single pkg
        repo.create_ebuild("cat/pkg-1")
        r = EbuildRepo(path)
        assert len(r) == 1
        assert "cat/pkg-1" in r

        # file path from string
        r = EbuildRepo(str(path))
        assert len(r) == 1
        assert "cat/pkg-1" in r

        # multiple pkgs
        repo.create_ebuild("cat/pkg-2")
        r = EbuildRepo(path)
        assert len(r) == 2
        assert "cat/pkg-1" in r
        assert "cat/pkg-2" in r

        # base repo type
        r = Repo(path)
        assert "cat/pkg-1" in r

    def test_contains_path(self, make_ebuild_repo):
        r1 = make_ebuild_repo()
        r2 = make_ebuild_repo()
        pkg1 = r1.create_pkg("cat/pkg-1")
        pkg2 = r2.create_pkg("cat/pkg-1")

        # Path objects
        assert Path("cat") in r1
        assert Path("cat/pkg") in r1
        assert Path("cat/pkg2") not in r1
        assert pkg1.path in r1
        assert pkg2.path not in r1
        assert pkg1.path not in r2
        assert pkg2.path in r2

    def test_eapi(self, make_raw_ebuild_repo):
        # non-present defaults to EAPI 0 which isn't supported
        repo = make_raw_ebuild_repo(eapi=None)
        with pytest.raises(InvalidRepo, match="unsupported EAPI: 0"):
            EbuildRepo(repo.path)

        # invalid EAPI
        repo = make_raw_ebuild_repo(eapi="abc123")
        with pytest.raises(InvalidRepo, match="unsupported EAPI: abc123"):
            EbuildRepo(repo.path)

        # defaults to latest EAPI
        repo = make_raw_ebuild_repo()
        r = EbuildRepo(repo.path)
        assert r.eapi is EAPI_LATEST_OFFICIAL

        # explicitly force latest EAPI
        repo = make_raw_ebuild_repo(eapi=EAPI_LATEST_OFFICIAL)
        r = EbuildRepo(repo.path)
        assert r.eapi is EAPI_LATEST_OFFICIAL

    def test_masters(self, testdata_config):
        # primary repo
        primary_repo = testdata_config.repos["dependent-primary"]
        assert not primary_repo.masters

        # dependent repo
        secondary_repo = testdata_config.repos["dependent-secondary"]
        assert secondary_repo.masters == (primary_repo,)

    @pytest.mark.parallel
    def test_pkg_metadata_regen(self, testdata_config, tmpdir):
        orig_repo = testdata_config.repos["metadata-gen"]
        # copy original repo to a temp dir
        repo_path = shutil.copytree(orig_repo.path, tmpdir.join("repo"))
        repo = EbuildRepo(repo_path)
        metadata_path = repo.path.joinpath("metadata/md5-cache")

        def metadata_content():
            """Yield metadata file names and content."""
            for root, _dirs, files in os.walk(metadata_path):
                for name in files:
                    with open(os.path.join(root, name)) as f:
                        yield (name, f.read())

        # record expected metadata file content
        expected = sorted(metadata_content())
        # wipe metadata
        shutil.rmtree(metadata_path)
        # regenerate metadata
        repo.pkg_metadata_regen()
        # verify new data matches original
        data = sorted(metadata_content())
        assert data == expected


class TestEbuildRepoMetadata:
    def test_arches(self, make_ebuild_repo):
        # empty
        repo = make_ebuild_repo()
        assert repo.metadata.arches == []

        # existing
        repo = make_ebuild_repo(arches=["amd64", "arm64"])
        assert repo.metadata.arches == ["amd64", "arm64"]

    def test_categories(self, make_ebuild_repo):
        # empty
        repo = make_ebuild_repo()
        assert repo.metadata.categories == []

        # existing
        repo = make_ebuild_repo(categories=["cat1", "cat2"])
        assert repo.metadata.categories == ["cat1", "cat2"]
