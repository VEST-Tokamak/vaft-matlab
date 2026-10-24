# Installation

vaft-matlab is a plain folder that you add to the MATLAB path. You install
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

## 1. Get IMAS-MATLAB

Pick one of these options:

**A. Your site already has it.** Load it, for example with
`module load IMAS-MATLAB` or `source <install_dir>/bin/al_env.sh`, then
start MATLAB.

**B. Build it with vaft-matlab's installer.** This works on Linux and Apple
silicon macOS:

```bash
git clone https://github.com/iterorganization/IMAS-MATLAB.git
git clone https://github.com/iterorganization/IMAS-Core.git
git clone https://github.com/iterorganization/IMAS-Data-Dictionary.git
git clone https://github.com/VEST-Tokamak/vaft-matlab.git

bash vaft-matlab/install/install_imas_matlab.sh --source IMAS-MATLAB
bash vaft-matlab/install/start_matlab.sh        # MATLAB with IMAS + vaft on the path
```

The installer builds your committed revisions in a separate work folder.
On macOS it applies a small patch, kept in this repository, to that copy.
It then installs into `~/.local/vaft-matlab/imas` and runs the integration
tests. See [install/README.md](../install/README.md) for prerequisites,
options and what the patch changes.

**C. Build it with upstream's instructions** (Linux), following
[Building and installing IMAS-MATLAB](https://imas-matlab.readthedocs.io/en/latest/building_installing.html).
Then run `source <install_dir>/bin/al_env.sh` before starting MATLAB.

### Notes

- If you add folders yourself, add the compiled toolbox folder (the one
  containing `ids_get.mex*`). Don't add the IMAS-MATLAB *source* folder
  `matlab/`: its `.m` files hold only help text, and `vaft.doctor` reports
  them as a failure.
- With the HDF5 backend, set `HDF5_USE_FILE_LOCKING=FALSE` on shared
  filesystems. `start_matlab.sh` does this for you.

## 2. Install vaft-matlab

```bash
git clone https://github.com/VEST-Tokamak/vaft-matlab.git
```

```matlab
addpath("/path/to/vaft-matlab")
savepath        % optional: keep it for future sessions
```

Add only the repository root. MATLAB finds `+vaft` from there.
`install/start_matlab.sh` adds the root for you.

## 3. Check

```matlab
vaft.doctor
```

Every line should be `[OK]` or `[INFO]`. Each `[FAIL]` line includes a hint.

## Uninstall

```matlab
rmpath("/path/to/vaft-matlab"); savepath
```

To remove an IMAS-MATLAB install made by the installer:

```bash
bash install/install_imas_matlab.sh --uninstall
```
