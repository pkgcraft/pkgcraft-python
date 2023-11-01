import glob
import operator
import os
import tomllib
from pathlib import Path

from pkgcraft.config import Config
from pkgcraft.dep import Dep
from pkgcraft.error import InvalidRepo

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
        for path in sorted(glob.glob(f"{DATADIR}/repos/*")):
            try:
                self._config.add_repo(path, id=os.path.basename(path), external=False)
            except InvalidRepo:
                # ignore purposely broken repos
                pass

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

    def ebuild_repo(self, id):
        """Return the ebuild repo with the given identifier."""
        return self._config.repos[id]

    def ebuild_pkg(self, dep_str):
        """Return the ebuild package with the given dep identifier."""
        dep = Dep(dep_str)
        return self._config.repos[dep.repo][dep]


TEST_DATA = TestData()
