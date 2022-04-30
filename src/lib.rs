use std::{error, fmt};

use pyo3::exceptions::PyException;
use pyo3::prelude::*;
use pyo3::{create_exception, wrap_pymodule, PyErr};

mod atom;
mod config;
mod parse;
mod repo;

#[derive(Debug)]
struct Error(pkgcraft::Error);

impl error::Error for Error {}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

create_exception!(
    pkgcraft,
    PkgcraftError,
    PyException,
    "Generic pkgcraft error."
);

impl From<Error> for PyErr {
    fn from(err: Error) -> PyErr {
        PkgcraftError::new_err(err.0.to_string())
    }
}

#[pymodule]
fn pkgcraft(py: Python, m: &PyModule) -> PyResult<()> {
    m.add_wrapped(wrap_pymodule!(parse::module))?;
    m.add_class::<atom::Atom>()?;
    m.add_class::<atom::Version>()?;
    m.add_class::<config::Config>()?;
    m.add_class::<repo::Repo>()?;
    m.add("PkgcraftError", py.get_type::<PkgcraftError>())?;
    Ok(())
}
