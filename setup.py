from setuptools import setup
from setuptools_rust import Binding, RustExtension

extensions=[RustExtension("pkgcraft", binding=Binding.PyO3)]

setup(
    name="pkgcraft",
    version="0.0.1",
    rust_extensions=extensions,
    packages=["src"],
    zip_safe=False,
)
