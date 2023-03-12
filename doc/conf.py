# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

import os
import sys

sys.path.insert(0, os.path.abspath("../src/"))
from pkgcraft.__version__ import version as pkgcraft_version

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = "pkgcraft"
copyright = "2021-2023, Tim Harder"
author = "Tim Harder"
version = pkgcraft_version
release = pkgcraft_version

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    "sphinx.ext.autodoc",
    "sphinx.ext.intersphinx",
    "sphinx.ext.todo",
    "sphinx.ext.viewcode",
]

intersphinx_mapping = {
    "python": ("https://docs.python.org/3/", None),
}

templates_path = ["_templates"]
exclude_patterns = []

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = "alabaster"
# html_static_path = ['_static']

# https://alabaster.readthedocs.io/en/latest/customization.html
html_theme_options = {
    "show_powered_by": False,
    "github_user": "pkgcraft",
    "github_repo": "pkgcraft-python",
    "github_banner": True,
    "show_related": False,
    "note_bg": "#FFF59C",
}
