use camino::Utf8Path;
use pkgcraft::repo;
use pkgcraft::repo::Repo as RepoTrait;
use pyo3::prelude::*;

use crate::Error;

#[pyclass]
pub(super) struct Repo(repo::Repository);

#[pymethods]
impl Repo {
    #[new]
    #[args(id = "None")]
    fn new(path: &str, id: Option<&str>) -> PyResult<Self> {
        let path = Utf8Path::new(path);
        let id = match id {
            Some(id) => id,
            None => path.as_str(),
        };
        let (_format, repo) = repo::Repository::from_path(id, path).map_err(Error)?;
        Ok(Self(repo))
    }

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
