use std::sync::Arc;

use pkgcraft::repo;
use pkgcraft::repo::Repo as RepoTrait;
use pyo3::prelude::*;

#[pyclass]
pub(super) struct Repo(pub(super) Arc<repo::Repository>);

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
}
