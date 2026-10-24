# Compatibility

The supported ranges come from installations that were actually tested. A
configuration not listed here may work, but it hasn't been checked.

## Tested configurations

| Date | Platform | MATLAB | IMAS-MATLAB (HLI) | IMAS-Core (AL) | Data Dictionary | Backend | Result |
|---|---|---|---|---|---|---|---|
| 2026-10-25 | macOS, arm64 | R2026b | 5.5.0+63-gf8208f6 (local macOS patches) | 5.6.0.1 | 4.1.1-15-gcc8fd4f | HDF5 | unit + integration pass |
| CI | Ubuntu (GitHub-hosted) | R2024b | not installed | – | – | – | unit tests only |

Notes:

- The macOS row uses an IMAS-MATLAB build compiled against MATLAB R2025b
  that also loads in R2026b. macOS isn't an upstream-supported platform.
- The version strings above are the `imas_versions()` output
  (`hli_version`, `al_version`, `dd_version`).

## Minimum versions

| Component | Minimum | Reason |
|---|---|---|
| MATLAB | R2024b | the baseline checked by `vaft.doctor` and used in CI. The code relies on `arguments` blocks, `dictionary` and `isMATLABReleaseOlderThan` |
| IMAS-MATLAB | 5.x | URI-based `imas_open` and `ids_get(idx, name, occurrence)` |
| Python | none | not needed. Python 3.11 is the target for future interoperability |

## Adding a row

Run `vaft.doctor` and `buildtool integration` on the new configuration.
Then add a row with the `imas_versions()` values and the date.
