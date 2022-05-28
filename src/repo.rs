use std::sync::Arc;

use pkgcraft::repo;
use pkgcraft::repo::Repository;
use pyo3::basic::CompareOp;
use pyo3::prelude::*;

#[pyclass]
pub(super) struct Repo(pub(super) Arc<repo::Repo>);

#[pymethods]
impl Repo {
    #[getter]
    fn id(&self) -> &str {
        self.0.id()
    }

    fn __str__(&self) -> PyResult<String> {
        Ok(self.0.id().to_string())
    }

    fn __repr__(&self) -> PyResult<String> {
        Ok(format!("<Repo '{}' at {:p}>", self.0, self))
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
