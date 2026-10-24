# vaft-matlab

MATLAB-native frontend for the [Versatile Analysis Framework for Tokamak (VAFT)](https://github.com/VEST-Tokamak/vaft).

vaft-matlab reads IMAS data through the official
[IMAS-MATLAB](https://github.com/iterorganization/IMAS-MATLAB) library and
returns ordinary MATLAB IDS structures. It doesn't reimplement IMAS I/O or
VAFT's scientific algorithms. Python VAFT remains the reference
implementation for those, and you don't need Python for data access.

> **Status: 0.1.0, initial release.** Only the minimal API below exists.
> See [Planned](#planned) for what comes next.

## Quick start

```matlab
vaft.doctor();                                  % check dependencies

entry = vaft.open("imas:hdf5?path=./test_db", Mode="read");
eq = entry.get("equilibrium", Occurrence=0);    % native IMAS-MATLAB struct
entry.close();
```

## Installation

1. Install [IMAS-MATLAB](https://imas-matlab.readthedocs.io/) together with
   IMAS-Core and the IMAS Data Dictionary, and make it available in MATLAB
   (usually `source <install_dir>/bin/al_env.sh` before starting MATLAB).
2. Clone this repository and add it to the MATLAB path:

   ```matlab
   addpath("/path/to/vaft-matlab")
   savepath   % optional
   ```

3. Run `vaft.doctor` to check the result.

[docs/installation.md](docs/installation.md) has platform notes.
[install/](install/README.md) can build IMAS-MATLAB for you on Linux and
Apple silicon macOS. [docs/compatibility.md](docs/compatibility.md) lists the tested
versions.

## Implemented

| API | Description |
|---|---|
| `vaft.doctor()` | Reports MATLAB, IMAS-MATLAB, IMAS-Core, Data Dictionary and optional Python VAFT status, with a hint for each problem |
| `vaft.open(uri, Mode="read")` | Opens an existing Data Entry (`imas_open`) and returns a `vaft.DataEntry` |
| `entry.get(name, Occurrence=n)` | Reads an IDS (`ids_get`). The default occurrence is 0 |
| `entry.close()` | Closes the entry (`imas_close`). Safe to call more than once, and also runs when the handle is deleted |
| `vaft.version()` | Package version |

## Planned

These are tracked as follow-up issues and are **not implemented yet**:

- DD / DDView / DDCollection abstractions ([vaft#1127](https://github.com/VEST-Tokamak/vaft/issues/1127))
- semantic occurrence selection (`ids_properties.name`)
- partial IDS loading, time-slice and time-window APIs
- writing IDSs and validation workflows
- MATLAB-native plotting ([vaft#1208](https://github.com/VEST-Tokamak/vaft/issues/1208))
- an optional bridge to Python VAFT (`vaft.formula`, `vaft.process`, `vaft.code`, `vaft.validation`)
- HSDS access, GUIs, multi-machine workflows

## Architecture

```
your MATLAB code
      │
   +vaft            thin MATLAB-native adapter (this repository)
      │
 IMAS-MATLAB        official IDS structures and I/O (LGPL-3.0, installed separately)
      │
  IMAS-Core         storage backends (HDF5, MDSplus, UDA, ...)
```

Read [docs/architecture.md](docs/architecture.md) for the design and how it
relates to Python VAFT.

## Testing

```matlab
buildtool            % static checks + unit tests (no IMAS needed)
buildtool integration % needs IMAS-MATLAB on the path
```

## License

vaft-matlab is licensed under the [Apache License 2.0](LICENSE).

IMAS-MATLAB, IMAS-Core and the IMAS Data Dictionary are separate projects,
distributed by the ITER Organization under their own licenses (IMAS-MATLAB
uses LGPL-3.0). This repository doesn't include or redistribute them. See
[NOTICE](NOTICE).
