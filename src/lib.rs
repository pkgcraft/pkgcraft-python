use std::{error, fmt};

use pyo3::basic::CompareOp;
use pyo3::exceptions::PyException;
use pyo3::prelude::*;
use pyo3::{create_exception, PyErr};

use pkgcraft::atom;

#[derive(Debug)]
struct Error(pkgcraft::Error);

impl error::Error for Error {}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

create_exception!(pkgcraft, PkgcraftError, PyException);

impl From<Error> for PyErr {
    fn from(err: Error) -> PyErr {
        PkgcraftError::new_err(err.0.to_string())
    }
}

#[pyclass]
struct Atom(atom::Atom);

#[pymethods]
impl Atom {
    #[new]
    fn new(s: &str, eapi: Option<&str>) -> PyResult<Self> {
        Ok(Self(atom::Atom::new(s, eapi).map_err(Error)?))
    }

    #[getter]
    fn category(&self) -> &str {
        &self.0.category
    }

    #[getter]
    fn package(&self) -> &str {
        &self.0.package
    }

    #[getter]
    fn slot(&self) -> Option<&str> {
        self.0.slot()
    }

    #[getter]
    fn subslot(&self) -> Option<&str> {
        self.0.subslot()
    }

    #[getter]
    fn slot_op(&self) -> Option<&str> {
        self.0.slot_op()
    }

    #[getter]
    fn use_deps(&self) -> Option<Vec<String>> {
        self.0.use_deps.as_ref().cloned()
    }

    #[getter]
    fn repo(&self) -> Option<&str> {
        self.0.repo()
    }

    #[getter]
    fn fullver(&self) -> Option<String> {
        self.0.fullver()
    }

    #[getter]
    fn key(&self) -> String {
        self.0.key()
    }

    #[getter]
    fn cpv(&self) -> String {
        self.0.cpv()
    }

    fn __str__(&self) -> PyResult<String> {
        Ok(format!("{}", self.0))
    }

    fn __repr__(&self) -> PyResult<String> {
        Ok(format!("<Atom '{}' at {:p}>", self.0, self))
    }

    fn __richcmp__(&self, other: PyRef<Atom>, op: CompareOp) -> bool {
        match op {
            CompareOp::Eq => self.0 == other.0,
            CompareOp::Ne => self.0 != other.0,
            CompareOp::Lt => self.0 < other.0,
            CompareOp::Gt => self.0 > other.0,
            CompareOp::Le => self.0 <= other.0,
            CompareOp::Ge => self.0 >= other.0,
        }
    }
}

#[pymodule]
fn pkgcraft(_py: Python<'_>, m: &PyModule) -> PyResult<()> {
    m.add_class::<Atom>()?;
    Ok(())
}
