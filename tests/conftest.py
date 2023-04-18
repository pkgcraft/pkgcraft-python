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

DATADIR = Path(__file__).parent.parent / "testdata"
TOMLDIR = DATADIR / "toml"


@pytest.fixture(scope="session")
def toml_data():
    """All toml test data presented as a dict using relative file paths as keys."""
    d = {}
    for path in glob.glob(f"{TOMLDIR}/**/*.toml", recursive=True):
        with open(path, "rb") as f:
            key = path.removeprefix(f"{TOMLDIR}/")
            d[key] = tomllib.load(f)
    return d
