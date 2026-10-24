# Architecture

## Goals

vaft-matlab gives MATLAB users access to VAFT and IMAS data in the usual
MATLAB style, without a second implementation of anything that already
exists. It follows three rules:

1. **IMAS-MATLAB is the only data-access layer.** IDS definitions, I/O,
   serialization and validation all come from the official IMAS-MATLAB
   library. vaft-matlab never reads storage files itself and never defines
   its own IDS types.
2. **Python VAFT is the reference for scientific algorithms.** Formulas,
   processing, external-code interfaces and validation in `vaft` (Python)
   aren't ported. A future bridge may call them, but only as an optional
   extra.
3. **The API is MATLAB-native.** It uses a `+vaft` namespace, `handle`
   classes, name-value arguments, `arguments` validation and MATLAB error
   identifiers, and returns ordinary MATLAB data and graphics objects. It
   doesn't expose Python objects or mimic Python syntax.

## Layers

```
┌───────────────────────────────────────────────┐
│ user scripts, live scripts, apps              │
├───────────────────────────────────────────────┤
│ +vaft  (this repo)                            │
│   open / DataEntry / doctor / version         │  implemented
│   +plot, DD abstractions, +python bridge      │  planned
├──────────────────────┬────────────────────────┤
│ IMAS-MATLAB (LGPL)   │ Python VAFT (optional) │
│ imas_open, ids_get…  │ via MATLAB py.*        │
├──────────────────────┴────────────────────────┤
│ IMAS-Core backends (HDF5, MDSplus, UDA) + DD   │
└───────────────────────────────────────────────┘
```

### `vaft.DataEntry`

`vaft.DataEntry` is a `handle` around one IMAS-MATLAB Data Entry index:

| DataEntry | IMAS-MATLAB |
|---|---|
| constructor / `vaft.open(uri, Mode="read")` | `imas_open(uri, 40)` (`OPEN_PULSE`) |
| `get(name, Occurrence=n)` | `ids_get(idx, name, n)` |
| `close()`, `delete` | `imas_close(idx)` |

- `get` returns the struct from `ids_get` unchanged. There's no separate
  vaft IDS type.
- When `imas_open` returns a negative index or throws, the constructor
  raises `vaft:DataEntry:openFailed`, with the upstream error attached as
  the cause.
- Calls on a closed entry raise `vaft:DataEntry:closed`.
- `close` is idempotent. The destructor closes the entry and turns any
  error into the warning `vaft:DataEntry:closeFailed`.
- Before opening, the constructor checks that the compiled IMAS functions
  are present (`vaft.internal.validateIMAS`), so a missing installation
  gives `vaft:imas:notFound` instead of an "undefined function" error.

IMAS-MATLAB calls go through `vaft.internal.imasBackend`, a struct of
function handles. Unit tests swap in a recording test double
(`tests/support/FakeBackend.m`), so the lifecycle logic is tested without
IMAS. This is an internal seam and not a public extension point.

### `vaft.doctor`

`vaft.doctor` only reports and never installs or changes anything. It
checks the MATLAB release, whether the IMAS-MATLAB functions are compiled
MEX files and not just the help-only `.m` files in the source tree,
`imas_versions()`, the Data Dictionary environment, the HDF5 locking
setting, and (for information only) Python VAFT.

## Shared scientific semantics

vaft-matlab follows the conventions of VAFT and IMAS. It doesn't define
its own:

- IMAS Data Dictionary versions and IDS structure, as provided by the
  installed IMAS-MATLAB;
- numeric IDS occurrences. Semantic selection through
  `ids_properties.name` is planned, following the `DD`/`DDView`/`DDCollection`
  contracts in [vaft#1127](https://github.com/VEST-Tokamak/vaft/issues/1127);
- DD units, coordinates and COCOS conventions;
- provenance and validation metadata stored in the IDS itself.

## Plotting (planned)

MATLAB plotting will follow the backend-independent view models from
[vaft#1208](https://github.com/VEST-Tokamak/vaft/issues/1208). Plot
preparation stays reusable, and MATLAB rendering produces ordinary MATLAB
graphics objects. The Python-to-MATLAB rendering backend described in
#1208 is a separate path that this repository doesn't depend on.

## Related

- [vaft#1640](https://github.com/VEST-Tokamak/vaft/issues/1640): research
  modality, portability and architecture diagrams
- [IMAS-MATLAB documentation](https://imas-matlab.readthedocs.io/)

## Adding modules

Each new namespace (`+vaft/+plot`, `+vaft/+python`, DD abstractions)
should arrive with a working implementation, tests and documentation.
Don't add empty placeholder folders.
