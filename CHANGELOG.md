# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Before 1.0.0, minor versions may change the public API.

## [Unreleased]

### Added

- `install/install_imas_matlab.sh`, which builds IMAS-MATLAB, IMAS-Core and the Data Dictionary from your own source trees on Linux and Apple silicon macOS, applies the macOS patches to staged copies, verifies the install with `vaft.doctor` and the integration tests, and records a manifest.
- `install/start_matlab.sh`, which starts MATLAB with IMAS-MATLAB and vaft-matlab on the path.
- macOS patches for IMAS-MATLAB (`install/imas-matlab/macos.patch`) and IMAS-Core (`install/imas-core/macos.patch`), both LGPL-3.0.

### Changed

- The integration CI job runs on a self-hosted runner, on manual dispatch only, and never for pull requests.

## [0.1.0] - 2026-10-25

### Added

- `+vaft` namespace package.
- `vaft.doctor`, which reports the status of MATLAB, IMAS-MATLAB, IMAS-Core, the Data Dictionary and optional Python VAFT.
- `vaft.open` and the `vaft.DataEntry` handle class, which wrap `imas_open`, `ids_get` (with explicit occurrence) and `imas_close`.
- `vaft.version`.
- Unit tests that need no IMAS installation, and integration tests against a generated HDF5 Data Entry.
- GitHub Actions CI, documentation, and issue templates.

[Unreleased]: https://github.com/VEST-Tokamak/vaft-matlab/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/VEST-Tokamak/vaft-matlab/releases/tag/v0.1.0
