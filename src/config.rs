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

    #[args(id = "None", priority = "None")]
    fn add_repo(&mut self, path: &str, id: Option<&str>, priority: Option<i32>) -> PyResult<Repo> {
        let id = id.unwrap_or(path);
        let priority = priority.unwrap_or(0);
        let repo = self.0.add_repo(id, priority, path).map_err(Error)?;
        Ok(Repo(repo))
    }

    #[getter]
    fn repos(&self) -> HashMap<String, Repo> {
        let mut map = HashMap::<String, Repo>::new();
        for (id, repo) in self.0.repos.iter() {
            map.insert(id.to_string(), Repo(repo.clone()));
        }
        map
    }
}
