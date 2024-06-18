import glob
import operator
import os
import tomllib
from pathlib import Path

from pkgcraft.config import Config

# global test data path
DATADIR = Path(__file__).parent.parent / "testdata"

OperatorMap = {
    "<": operator.lt,
    ">": operator.gt,
    "==": operator.eq,
    "!=": operator.ne,
    ">=": operator.ge,
    "<=": operator.le,
}

OperatorIterMap = {
    "<": [operator.lt, operator.le],
    ">": [operator.gt, operator.ge],
    "==": [operator.eq],
    "!=": [operator.ne],
    ">=": [operator.ge],
    "<=": [operator.le],
}


class TestData:
    """Wrapper for bundled test data."""

    def __init__(self):
        self._config = Config()

        # load repos
        for path in sorted(glob.glob(f"{DATADIR}/repos/valid/*")):
            self._config.add_repo(path, id=os.path.basename(path), external=False)

        # load toml files
        self._toml = {}
        toml_dir = DATADIR / "toml"
        for path in glob.glob(f"{toml_dir}/**/*.toml", recursive=True):
            with open(path, "rb") as f:
                key = path.removeprefix(f"{toml_dir}/")
                self._toml[key] = tomllib.load(f)

    def toml(self, id):
        """Return the parsed toml data with the given relative path identifier."""
        return self._toml[id]

    @property
    def repos(self):
        """Return all registered repos from the shared test data."""
        return self._config.repos


TEST_DATA = TestData()
