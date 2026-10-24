# Installing IMAS-MATLAB for vaft-matlab

vaft-matlab needs a compiled IMAS-MATLAB, together with IMAS-Core and the
IMAS Data Dictionary. This folder builds one from source trees you supply,
on Linux and Apple silicon macOS, and checks it with vaft-matlab's
integration tests.

| File | Purpose |
|---|---|
| `install_imas_matlab.sh` | stage, patch (macOS only), build, install, verify, and write a manifest |
| `start_matlab.sh` | start MATLAB with IMAS-MATLAB and vaft-matlab on the path |
| `imas-matlab/macos.patch` | macOS build fixes for IMAS-MATLAB (LGPL-3.0, see its header) |
| `imas-core/macos.patch` | one-line macOS fix to IMAS-Core's `al_env.sh` (LGPL-3.0) |

If your site already provides IMAS-MATLAB (for example `module load
IMAS-MATLAB`), you don't need this folder. Load the module and run
`vaft.doctor`.

## Prerequisites (install these yourself)

- MATLAB R2024b or newer, licensed
- git, CMake 3.16 or newer, pkg-config, a C/C++ compiler
- Boost and HDF5 development packages
  - macOS: `xcode-select --install` and `brew install boost hdf5 cmake pkgconf`
  - Ubuntu: `sudo apt install build-essential cmake pkg-config libboost-all-dev libhdf5-dev`
- Python 3 with `venv`. The upstream Data Dictionary build creates a venv
  in the build folder and installs `saxonche` from PyPI, so the build needs
  network access.

The script doesn't install any of these for you.

## 1. Get the sources

Clone the repositories side by side. The revisions you check out are the
ones that get built:

```bash
git clone https://github.com/iterorganization/IMAS-MATLAB.git
git clone https://github.com/iterorganization/IMAS-Core.git
git clone https://github.com/iterorganization/IMAS-Data-Dictionary.git
```

## 2. Build and install

```bash
bash install/install_imas_matlab.sh --source /path/to/IMAS-MATLAB
```

- IMAS-Core and the Data Dictionary are found next to IMAS-MATLAB (or under
  their legacy names `al-core` and `data-dictionary`). Pass `--core` and
  `--dd` if they're somewhere else.
- The default prefix is `~/.local/vaft-matlab/imas`. Change it with
  `--prefix PATH`.
- MATLAB defaults to the newest `/Applications/MATLAB_R*.app` on macOS and
  the `matlab` on `PATH` on Linux. Change it with `--matlab-root PATH`.
- The build uses the HDF5 backend only. MDSplus and UDA aren't built (on
  macOS, IMAS-Core doesn't support them).

What the script does:

1. It clones the **committed HEAD** of each tree into `<prefix>.build/`, in
   the layout upstream's `AL_DEVELOPMENT_LAYOUT` expects. Your trees are
   never modified, and uncommitted changes in them aren't built (you'll see
   a warning).
2. On macOS, it applies `imas-matlab/macos.patch` and `imas-core/macos.patch`
   to those copies.
3. It configures, builds and installs with CMake.
4. It writes `vaft-matlab-install.json` into the prefix, recording the
   source revisions, the patch SHA-256 digests, MATLAB, and the CMake
   options.
5. It runs `vaft.doctor` and `buildtool integration` as the acceptance
   test. The script fails if either fails, unless you pass `--skip-tests`.

## 3. Use it

```bash
bash install/start_matlab.sh --prefix ~/.local/vaft-matlab/imas
bash install/start_matlab.sh -batch "vaft.doctor"     # default prefix
```

`start_matlab.sh` sources `<prefix>/bin/al_env.sh`, adds `<prefix>/toolbox`
and this repository to `MATLABPATH`, and starts MATLAB. It changes no shell
profile. You can also set `VAFT_IMAS_PREFIX` once in your environment.

## Checking and removing

```bash
bash install/install_imas_matlab.sh --prefix ~/.local/vaft-matlab/imas --check-only
bash install/install_imas_matlab.sh --prefix ~/.local/vaft-matlab/imas --uninstall
```

`--uninstall` only removes a prefix that contains this script's manifest.

## About the macOS patches

IMAS-MATLAB upstream targets Linux and Windows. The two patches are the
smallest set of changes that makes it build and load on Apple silicon. Each
patch's header explains what it changes. Both are LGPL-3.0, like the code
they modify, and neither is covered by this repository's Apache-2.0
license.

- `imas-matlab/macos.patch` changes `CMakeLists.txt` and `ids_validate.xsl`:
  it fixes the C MEX build, sets rpaths, and handles `uint`.
- `imas-core/macos.patch` changes `common/al_env.sh.in`, so that
  `IMAS_VERSION` is set without GNU `grep -P`.

| Repository | Revision | Result |
|---|---|---|
| IMAS-MATLAB | `f8208f6` (5.5.0-63) | applies, builds, integration tests pass |
| IMAS-MATLAB | `40c61b2` (develop, 2026-10) | applies cleanly |
| IMAS-Core | `1c58af48` (5.6.0-1) | applies, builds |
| IMAS-Core | `fd7ef3d7` (develop, 2026-10) | applies cleanly |
| IMAS-Data-Dictionary | `4.1.1-15-gcc8fd4f` | no patch needed |

Because the patches are applied to the staged copies, IMAS-MATLAB reports
its version with a `-dirty` suffix (for example
`hli_version=5.5.0+63-gf8208f6-dirty`). That's expected. The manifest
records exactly which patch was applied.

If a patch stops applying after an upstream change, the script stops
before building. Update the patch, or check out a revision from the table.
The goal is to upstream these changes so the patches can eventually be
removed.
