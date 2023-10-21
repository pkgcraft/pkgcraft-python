import os

pytest_plugins = ["pkgcraft._pytest"]

# TODO: drop this when pkgcraft source handling is reworked
os.environ["PKGCRAFT_TEST"] = "1"
