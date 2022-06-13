use pkgcraft::{atom, utils::hash};
use pyo3::basic::CompareOp;
use pyo3::prelude::*;

use crate::Error;

#[pyclass]
pub(crate) struct Atom(pub(crate) atom::Atom);

#[pymethods]
impl Atom {
    #[new]
    fn new(s: &str, eapi: Option<&str>) -> PyResult<Self> {
        Ok(Self(atom::Atom::new(s, eapi).map_err(Error)?))
    }

    #[getter]
    fn category(&self) -> &str {
        self.0.category()
    }

    #[getter]
    fn package(&self) -> &str {
        self.0.package()
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
    fn use_deps(&self) -> Option<Vec<&str>> {
        self.0.use_deps()
    }

    #[getter]
    fn repo(&self) -> Option<&str> {
        self.0.repo()
    }

    #[getter]
    fn version(&self) -> Option<&str> {
        self.0.version().map(|x| x.as_str())
    }

    #[getter]
    fn revision(&self) -> Option<&str> {
        self.0.revision().map(|x| x.as_str())
    }

    #[getter]
    fn key(&self) -> String {
        self.0.key()
    }

    #[getter]
    fn cpv(&self) -> String {
        self.0.cpv()
    }

    fn __hash__(&self) -> Result<isize, PyErr> {
        Ok(hash(&self.0) as isize)
    }

    fn __str__(&self) -> PyResult<String> {
        Ok(format!("{}", self.0))
    }

    fn __repr__(&self) -> PyResult<String> {
        Ok(format!("<Atom '{}' at {:p}>", self.0, self))
    }

    fn __richcmp__(&self, other: PyRef<Self>, op: CompareOp) -> bool {
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

#[pyclass]
pub(crate) struct Version(pub(crate) atom::Version);

#[pymethods]
impl Version {
    #[new]
    fn new(s: &str) -> PyResult<Self> {
        Ok(Self(atom::Version::new(s).map_err(Error)?))
    }

    #[getter]
    fn revision(&self) -> &str {
        self.0.revision().as_str()
    }

    fn __hash__(&self) -> Result<isize, PyErr> {
        Ok(hash(&self.0) as isize)
    }

    fn __str__(&self) -> PyResult<String> {
        Ok(format!("{}", self.0))
    }

    fn __repr__(&self) -> PyResult<String> {
        Ok(format!("<Version '{}' at {:p}>", self.0, self))
    }

    fn __richcmp__(&self, other: PyRef<Self>, op: CompareOp) -> bool {
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
