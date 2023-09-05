import glob
import os
from pathlib import Path

# TODO: drop tomli usage when only supporting >=python-3.11
try:
    import tomllib
except ImportError:
    import tomli as tomllib

import pytest

pytest_plugins = ["pkgcraft._pytest"]

from pkgcraft.config import Config
from pkgcraft.error import InvalidRepo

DATADIR = Path(__file__).parent.parent / "testdata"
# TODO: drop this when pkgcraft source handling is reworked
os.environ["PKGCRAFT_TEST"] = "1"


@pytest.fixture(scope="session")
def testdata_toml():
    """All toml test data presented as a dict using relative file paths as keys."""
    d = {}
    toml_dir = DATADIR / "toml"
    for path in glob.glob(f"{toml_dir}/**/*.toml", recursive=True):
        with open(path, "rb") as f:
            key = path.removeprefix(f"{toml_dir}/")
            d[key] = tomllib.load(f)
    return d


@pytest.fixture(scope="session")
def testdata_config():
    """All repo test data loaded into a Config object."""
    config = Config()
    for path in sorted(glob.glob(f"{DATADIR}/repos/*")):
        try:
            config.add_repo(path, id=os.path.basename(path), external=False)
        except InvalidRepo:
            # ignore purposely broken repos
            pass
    return config
