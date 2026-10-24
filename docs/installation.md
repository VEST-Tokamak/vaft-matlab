# Installation

vaft-matlab is a plain folder that you add to the MATLAB path. Install
IMAS-MATLAB separately: this repository doesn't bundle it, and
`vaft.doctor` never installs it.

## Requirements

| Component | Required | Notes |
|---|---|---|
| MATLAB | yes | R2024b or newer. See [compatibility.md](compatibility.md) |
| IMAS-MATLAB | yes | compiled MEX toolbox |
| IMAS-Core | yes | built with IMAS-MATLAB |
| IMAS Data Dictionary | yes | built with IMAS-MATLAB |
| Python, Python VAFT | no | only for future interoperability |

## 1. Install IMAS-MATLAB

Follow the upstream guide,
[Building and installing IMAS-MATLAB](https://imas-matlab.readthedocs.io/en/latest/building_installing.html).
In short, on Linux:

```bash
git clone https://github.com/iterorganization/IMAS-MATLAB.git
cd IMAS-MATLAB
cmake -B build -D CMAKE_INSTALL_PREFIX=$HOME/al-install --preset=https
make -C build -j8 all install
```

On clusters with environment modules, IMAS may already be installed. In
that case, use for example `module load IMAS-MATLAB`.

### Make it available to MATLAB

Source the environment script before starting MATLAB:

```bash
source $HOME/al-install/bin/al_env.sh
matlab
```

This sets `MATLABPATH`, the library path, `IDSDEF_PATH` and
`IMAS_VERSION`. If you'd rather not use the script, add the compiled
toolbox folder (the one that contains `ids_get.mex*`) inside MATLAB with
`addpath`. Don't add the IMAS-MATLAB *source* folder `matlab/`: its `.m`
files hold only help text, and `vaft.doctor` reports them as a failure.

With the HDF5 backend, also set `HDF5_USE_FILE_LOCKING=FALSE` on shared
filesystems. You may also need `LD_PRELOAD=<hdf5>/lib/libhdf5_hl.so` when
starting MATLAB (see the upstream docs).

### macOS (Apple Silicon)

macOS isn't an officially supported IMAS-MATLAB platform. It can be built
locally with the HDF5 backend only (MDSplus and UDA are disabled on macOS),
using Homebrew `boost`, `hdf5`, `cmake` and `pkgconf`. Then start MATLAB
through the helper script that comes with IMAS-MATLAB:

```bash
MATLAB_BIN=/Applications/MATLAB_R2026b.app/bin/matlab \
  /path/to/IMAS-MATLAB/examples/start_matlab_mac.sh /path/to/install-mac
```

It sets `MATLABPATH=<install>/toolbox`, `IDSDEF_PATH`, `IMAS_VERSION` and
`HDF5_USE_FILE_LOCKING=FALSE`. Use `-batch "..."` after the install path
for non-interactive runs.

## 2. Install vaft-matlab

```bash
git clone https://github.com/VEST-Tokamak/vaft-matlab.git
```

```matlab
addpath("/path/to/vaft-matlab")
savepath        % optional: keep it for future sessions
```

Add only the repository root. MATLAB finds `+vaft` from there.

## 3. Check

```matlab
vaft.doctor
```

Every line should be `[OK]` or `[INFO]`. Each `[FAIL]` line includes a hint.

## Uninstall

```matlab
rmpath("/path/to/vaft-matlab"); savepath
```
