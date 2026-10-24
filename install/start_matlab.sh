#!/usr/bin/env bash
# Start MATLAB with IMAS-MATLAB and vaft-matlab on the path.
#
# Usage:
#   bash install/start_matlab.sh [--prefix PATH] [matlab arguments...]
#   bash install/start_matlab.sh --prefix ~/.local/vaft-matlab/imas -batch "vaft.doctor"
#
# Sources <prefix>/bin/al_env.sh (written by the IMAS-MATLAB install), puts
# <prefix>/toolbox and the vaft-matlab root at the front of MATLABPATH, and
# execs MATLAB. Nothing is written to disk.
#
#   --prefix PATH   IMAS-MATLAB install (default: $VAFT_IMAS_PREFIX, then
#                   $HOME/.local/vaft-matlab/imas)
#   MATLAB_ROOT     MATLAB installation (default: newest
#                   /Applications/MATLAB_R*.app on macOS, matlab on PATH on Linux)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
PREFIX="${VAFT_IMAS_PREFIX:-$HOME/.local/vaft-matlab/imas}"

if [ "${1:-}" = "--prefix" ]; then
  PREFIX="$2"
  shift 2
fi

if [ ! -f "${PREFIX}/bin/al_env.sh" ]; then
  echo "No IMAS-MATLAB install at ${PREFIX} (bin/al_env.sh missing)." >&2
  echo "Build one with install/install_imas_matlab.sh, or pass --prefix." >&2
  exit 1
fi

if [ -n "${MATLAB_ROOT:-}" ]; then
  matlab_bin="${MATLAB_ROOT}/bin/matlab"
elif [ "$(uname -s)" = "Darwin" ]; then
  matlab_app="$(ls -d /Applications/MATLAB_R*.app 2>/dev/null | sort | tail -n 1)"
  matlab_bin="${matlab_app:+${matlab_app}/bin/matlab}"
else
  matlab_bin="$(command -v matlab || true)"
fi
if [ -z "${matlab_bin}" ] || [ ! -x "${matlab_bin}" ]; then
  echo "MATLAB not found. Set MATLAB_ROOT to the folder containing bin/matlab." >&2
  exit 1
fi

# Upstream al_env.sh expands variables that may be unset.
set +u
# shellcheck disable=SC1091
. "${PREFIX}/bin/al_env.sh"
set -u
export HDF5_USE_FILE_LOCKING=FALSE
export MATLABPATH="${REPO_ROOT}:${PREFIX}/toolbox${MATLABPATH:+:${MATLABPATH}}"

exec "${matlab_bin}" "$@"
