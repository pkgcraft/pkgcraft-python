use pkgcraft::config;
use pyo3::prelude::*;

use crate::Error;

#[pyclass]
pub(crate) struct Config(config::Config);

#[pymethods]
impl Config {
    #[staticmethod]
    fn load() -> PyResult<Self> {
        Ok(Self(
            config::Config::new("pkgcraft", "", false).map_err(Error)?,
        ))
    }
}
