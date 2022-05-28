use std::collections::HashMap;

use pkgcraft::config;
use pyo3::prelude::*;

use crate::repo::Repo;
use crate::Error;

#[pyclass]
pub(super) struct Config(config::Config);

#[pymethods]
impl Config {
    #[staticmethod]
    fn load() -> PyResult<Self> {
        Ok(Self(
            config::Config::new("pkgcraft", "", false).map_err(Error)?,
        ))
    }

    #[args(id = "None")]
    fn add_repo(&mut self, path: &str, id: Option<&str>) -> PyResult<Repo> {
        let id = id.unwrap_or(path);
        let repo = self.0.repos.add(id, path).map_err(Error)?;
        Ok(Repo(repo))
    }

    #[getter]
    fn repos(&self) -> HashMap<String, Repo> {
        let mut map = HashMap::<String, Repo>::new();
        for (id, repo) in self.0.repos.repos.iter() {
            map.insert(id.clone(), Repo(repo.clone()));
        }
        map
    }
}
