import os
import sys
import datetime
sys.path.insert(0, os.path.abspath(".."))

project = "HealthyWear"
author = "Joaquín Ordieres"
copyright = f"{datetime.datetime.now().year}, {author}"

extensions = [
    "myst_parser",
    # "sphinx.ext.napoleon",
    # "sphinx.ext.autodoc",
    # "sphinx.ext.autosummary",
]

templates_path = ["_templates"]
exclude_patterns = [
    "_build", "Thumbs.db", ".DS_Store",
    "android/**/build", "ios/**/Pods", "*/build",
    "ApkFiles", "OutPutFiles", "windows/**/runner",
    "**/mdit_py_plugins/**/README.md",
    ".venv/**",
    "**/site-packages/**",
    "**/*.dist-info/**",
]

# autosummary_generate = True

html_theme = "sphinx_rtd_theme"
html_static_path = ["_static"]
