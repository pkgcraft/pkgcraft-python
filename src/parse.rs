use pkgcraft::atom;
use pyo3::prelude::*;

use crate::Error;

/// category(s, /)
/// --
///
/// Parse an atom category string.
#[pyfunction]
fn category(s: &str) -> PyResult<&str> {
    Ok(atom::parse::category(s).map_err(Error)?)
}

/// package(s, /)
/// --
///
/// Parse an atom package string.
#[pyfunction]
fn package(s: &str) -> PyResult<&str> {
    Ok(atom::parse::package(s).map_err(Error)?)
}

/// version(s, /)
/// --
///
/// Parse an atom version string.
#[pyfunction]
fn version(s: &str) -> PyResult<&str> {
    atom::Version::valid(s).map_err(Error)?;
    Ok(s)
}

/// repo(s, /)
/// --
///
/// Parse an atom repo string.
#[pyfunction]
fn repo(s: &str) -> PyResult<&str> {
    Ok(atom::parse::repo(s).map_err(Error)?)
}

/// cpv(s, /)
/// --
///
/// Parse an atom CPV string (e.g. cat/pkg-1).
#[pyfunction]
fn cpv(s: &str) -> PyResult<&str> {
    atom::Atom::valid_cpv(s).map_err(Error)?;
    Ok(s)
}

/// Parsing support to convert strings into various pkgcraft objects.
#[pymodule]
#[pyo3(name = "parse")]
pub(super) fn module(_py: Python, m: &PyModule) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(category, m)?)?;
    m.add_function(wrap_pyfunction!(package, m)?)?;
    m.add_function(wrap_pyfunction!(version, m)?)?;
    m.add_function(wrap_pyfunction!(repo, m)?)?;
    m.add_function(wrap_pyfunction!(cpv, m)?)?;
    Ok(())
}
