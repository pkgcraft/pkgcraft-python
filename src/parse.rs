use pkgcraft::atom;
use pyo3::prelude::*;

use crate::atom::Atom;
use crate::Error;

#[pyfunction]
fn category(s: &str) -> PyResult<&str> {
    Ok(atom::parse::category(s).map_err(Error)?)
}

#[pyfunction]
fn package(s: &str) -> PyResult<&str> {
    Ok(atom::parse::package(s).map_err(Error)?)
}

#[pyfunction]
fn repo(s: &str) -> PyResult<&str> {
    Ok(atom::parse::repo(s).map_err(Error)?)
}

#[pyfunction]
fn cpv(s: &str) -> PyResult<Atom> {
    Ok(Atom(atom::parse::cpv(s).map_err(Error)?))
}

#[pymodule]
#[pyo3(name = "parse")]
pub(super) fn module(_py: Python, m: &PyModule) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(category, m)?)?;
    m.add_function(wrap_pyfunction!(package, m)?)?;
    m.add_function(wrap_pyfunction!(repo, m)?)?;
    m.add_function(wrap_pyfunction!(cpv, m)?)?;
    Ok(())
}
