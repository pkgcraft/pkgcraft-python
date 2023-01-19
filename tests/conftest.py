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
    d = dict()
    for root, dirs, files in os.walk(TOMLDIR):
        for f in (f for f in files if f.endswith(".toml")):
            path = Path(root, f)
            with open(path, "rb") as f:
                key = str(path.relative_to(TOMLDIR))
                d[key] = tomllib.load(f)
    return d
