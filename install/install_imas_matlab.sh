#!/usr/bin/env bash
# Build and install IMAS-MATLAB (with IMAS-Core and the Data Dictionary) for
# vaft-matlab, from source trees you already hold.
#
# Usage:
#   bash install/install_imas_matlab.sh --source PATH [options]
#   bash install/install_imas_matlab.sh --prefix PATH --check-only
#   bash install/install_imas_matlab.sh --prefix PATH --uninstall
#
# vaft-matlab neither bundles nor fetches IMAS: which revisions were built is
# a statement the operator makes. Clone the three repositories yourself, as
# siblings or anywhere, and pass their paths:
#
#   git clone https://github.com/iterorganization/IMAS-MATLAB.git
#   git clone https://github.com/iterorganization/IMAS-Core.git
#   git clone https://github.com/iterorganization/IMAS-Data-Dictionary.git
#
# Your trees are never modified. The script clones the committed HEAD of each
# into a work folder, laid out the way upstream's AL_DEVELOPMENT_LAYOUT
# expects (IMAS-MATLAB, al-core, data-dictionary side by side). On macOS it
# applies install/imas-matlab/macos.patch and install/imas-core/macos.patch
# to those copies. It then builds with
# the HDF5 backend only, installs into the prefix, runs vaft-matlab's
# integration tests as the build's acceptance, and writes
# vaft-matlab-install.json into the prefix recording the source revisions,
# the patch digest, MATLAB, and the CMake options.
#
# Uncommitted changes in your trees are NOT built. Commit them, or build
# from a clean checkout.
#
# Nothing is installed system-wide and no shell profile is edited. Start
# MATLAB afterwards with install/start_matlab.sh --prefix PATH.
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
PATCH_FILE="${SCRIPT_DIR}/imas-matlab/macos.patch"
CORE_PATCH_FILE="${SCRIPT_DIR}/imas-core/macos.patch"
MANIFEST_NAME="vaft-matlab-install.json"

MATLAB_SOURCE="${IMAS_MATLAB_SOURCE_DIR:-}"
CORE_SOURCE="${IMAS_CORE_SOURCE_DIR:-}"
DD_SOURCE="${IMAS_DD_SOURCE_DIR:-}"
PREFIX=""
WORKDIR=""
MATLAB_ROOT="${MATLAB_ROOT:-}"
JOBS="4"
SKIP_TESTS=0
CHECK_ONLY=0
UNINSTALL=0
KEEP_WORKDIR=0

usage() {
  cat <<'EOF'
Usage: bash install/install_imas_matlab.sh --source PATH [options]

  --source PATH       IMAS-MATLAB source tree (or IMAS_MATLAB_SOURCE_DIR)
  --core PATH         IMAS-Core tree (default: <source>/../IMAS-Core or
                      ../al-core; or IMAS_CORE_SOURCE_DIR)
  --dd PATH           IMAS-Data-Dictionary tree (default:
                      <source>/../IMAS-Data-Dictionary or ../data-dictionary;
                      or IMAS_DD_SOURCE_DIR)
  --prefix PATH       install here (default: $HOME/.local/vaft-matlab/imas)
  --matlab-root PATH  MATLAB installation (default: newest
                      /Applications/MATLAB_R*.app on macOS, the matlab on PATH
                      on Linux; or MATLAB_ROOT)
  --workdir PATH      staging/build folder (default: <prefix>.build)
  --keep-workdir      keep the staging/build folder after a successful install
  --jobs N            parallel build jobs (default: 4)
  --skip-tests        do not run the acceptance tests after installing
  --check-only        only run the acceptance tests against --prefix
  --uninstall         remove the prefix, if this script created it
  -h, --help

Then start MATLAB with:  bash install/start_matlab.sh --prefix PATH
EOF
}

log()  { printf '[vaft-matlab] %s\n' "$*"; }
die()  { printf '\n[FAIL] %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --source)       MATLAB_SOURCE="$2"; shift 2 ;;
    --core)         CORE_SOURCE="$2"; shift 2 ;;
    --dd)           DD_SOURCE="$2"; shift 2 ;;
    --prefix)       PREFIX="$2"; shift 2 ;;
    --matlab-root)  MATLAB_ROOT="$2"; shift 2 ;;
    --workdir)      WORKDIR="$2"; shift 2 ;;
    --keep-workdir) KEEP_WORKDIR=1; shift ;;
    --jobs)         JOBS="$2"; shift 2 ;;
    --skip-tests)   SKIP_TESTS=1; shift ;;
    --check-only)   CHECK_ONLY=1; shift ;;
    --uninstall)    UNINSTALL=1; shift ;;
    -h|--help)      usage; exit 0 ;;
    *)              usage >&2; die "Unknown option: $1" ;;
  esac
done

PREFIX="${PREFIX:-$HOME/.local/vaft-matlab/imas}"
case "${PREFIX}" in /*) ;; *) PREFIX="$(pwd -P)/${PREFIX}" ;; esac
WORKDIR="${WORKDIR:-${PREFIX}.build}"
OS="$(uname -s)"

# --- MATLAB -----------------------------------------------------------------

find_matlab_root() {
  if [ -n "${MATLAB_ROOT}" ]; then
    printf '%s\n' "${MATLAB_ROOT}"
  elif [ "${OS}" = "Darwin" ]; then
    # Newest release by name (R2026b > R2026a > R2025b ...).
    ls -d /Applications/MATLAB_R*.app 2>/dev/null | sort | tail -n 1
  elif command -v matlab >/dev/null 2>&1; then
    local bin
    bin="$(command -v matlab)"
    bin="$(readlink -f "${bin}" 2>/dev/null || printf '%s' "${bin}")"
    dirname "$(dirname "${bin}")"
  fi
}

MATLAB_ROOT="$(find_matlab_root)"
[ -n "${MATLAB_ROOT}" ] && [ -x "${MATLAB_ROOT}/bin/matlab" ] \
  || die "MATLAB not found. Pass --matlab-root /path/to/MATLAB (the folder containing bin/matlab)."

# --- acceptance -------------------------------------------------------------

run_acceptance() {
  [ -f "${PREFIX}/bin/al_env.sh" ] || die "${PREFIX}/bin/al_env.sh not found; is ${PREFIX} an IMAS-MATLAB install?"
  log "Acceptance: vaft.doctor and buildtool integration with ${MATLAB_ROOT}"
  MATLAB_ROOT="${MATLAB_ROOT}" bash "${SCRIPT_DIR}/start_matlab.sh" --prefix "${PREFIX}" -batch \
    "cd('${REPO_ROOT}'); vaft.doctor; r = vaft.doctor(); assert(~any([r.Status] == \"FAIL\"), 'vaft.doctor reported FAIL'); buildtool integration"
}

if [ "${CHECK_ONLY}" -eq 1 ]; then
  run_acceptance
  log "Check passed for ${PREFIX}"
  exit 0
fi

# --- uninstall --------------------------------------------------------------

if [ "${UNINSTALL}" -eq 1 ]; then
  [ -d "${PREFIX}" ] || { log "Nothing to remove: ${PREFIX} does not exist."; exit 0; }
  [ -f "${PREFIX}/${MANIFEST_NAME}" ] \
    || die "${PREFIX} has no ${MANIFEST_NAME}; it was not created by this script, so it is left alone."
  rm -rf "${PREFIX}" "${WORKDIR}"
  log "Removed ${PREFIX}"
  exit 0
fi

# --- sources ----------------------------------------------------------------

[ -n "${MATLAB_SOURCE}" ] || { usage >&2; die "--source is required."; }
MATLAB_SOURCE="$(cd "${MATLAB_SOURCE}" && pwd -P)" || die "No such folder: ${MATLAB_SOURCE}"
PARENT="$(dirname "${MATLAB_SOURCE}")"

first_dir() {
  local d
  for d in "$@"; do
    if [ -d "${d}" ]; then (cd "${d}" && pwd -P); return 0; fi
  done
  return 1
}
CORE_SOURCE="$(first_dir ${CORE_SOURCE:+"${CORE_SOURCE}"} "${PARENT}/IMAS-Core" "${PARENT}/al-core")" \
  || die "IMAS-Core tree not found; pass --core PATH."
DD_SOURCE="$(first_dir ${DD_SOURCE:+"${DD_SOURCE}"} "${PARENT}/IMAS-Data-Dictionary" "${PARENT}/data-dictionary")" \
  || die "IMAS-Data-Dictionary tree not found; pass --dd PATH."

for tree in "${MATLAB_SOURCE}" "${CORE_SOURCE}" "${DD_SOURCE}"; do
  git -C "${tree}" rev-parse --git-dir >/dev/null 2>&1 || die "${tree} is not a git checkout."
  if [ -n "$(git -C "${tree}" status --porcelain --untracked-files=no)" ]; then
    log "WARNING: ${tree} has uncommitted changes; only its HEAD is built."
  fi
done

if [ -e "${PREFIX}" ] && [ ! -f "${PREFIX}/${MANIFEST_NAME}" ]; then
  die "${PREFIX} exists and was not created by this script. Choose another --prefix."
fi

# --- prerequisites ----------------------------------------------------------

for tool in git cmake pkg-config; do
  command -v "${tool}" >/dev/null 2>&1 || die "${tool} not found on PATH."
done
CMAKE_PREFIX_PATH_VALUE="${CMAKE_PREFIX_PATH:-}"
if [ "${OS}" = "Darwin" ]; then
  [ "$(uname -m)" = "arm64" ] || die "Only Apple silicon Macs are supported."
  command -v brew >/dev/null 2>&1 || die "Homebrew not found. Install boost, hdf5, cmake and pkgconf yourself, then rerun."
  for formula in boost hdf5; do
    brew list --versions "${formula}" >/dev/null 2>&1 \
      || die "Homebrew formula '${formula}' is missing: brew install boost hdf5 cmake pkgconf"
  done
  CMAKE_PREFIX_PATH_VALUE="$(brew --prefix boost);$(brew --prefix hdf5)${CMAKE_PREFIX_PATH_VALUE:+;${CMAKE_PREFIX_PATH_VALUE}}"
fi

# --- stage ------------------------------------------------------------------

stage() {
  # stage SRC NAME: clone SRC's HEAD (with tags, for version detection) into
  # WORKDIR/NAME without touching SRC.
  local src="$1" name="$2" rev
  rev="$(git -C "${src}" rev-parse HEAD)"
  git clone --quiet --no-checkout "${src}" "${WORKDIR}/${name}"
  git -C "${WORKDIR}/${name}" checkout --quiet --detach "${rev}"
  printf '%s\n' "${rev}"
}

log "Staging sources in ${WORKDIR}"
rm -rf "${WORKDIR}"
mkdir -p "${WORKDIR}"
MATLAB_REV="$(stage "${MATLAB_SOURCE}" IMAS-MATLAB)"
CORE_REV="$(stage "${CORE_SOURCE}" al-core)"
DD_REV="$(stage "${DD_SOURCE}" data-dictionary)"

apply_patch() {
  # apply_patch TREE PATCH: apply PATCH to the staged TREE, or stop.
  local tree="$1" patch="$2"
  log "Applying ${patch#"${SCRIPT_DIR}"/} to $(basename "${tree}")"
  git -C "${tree}" apply --check "${patch}" \
    || die "${patch} does not apply to ${tree} ($(git -C "${tree}" rev-parse --short HEAD)). See install/README.md for the tested revisions."
  git -C "${tree}" apply "${patch}"
}

PATCH_SHA=""
CORE_PATCH_SHA=""
if [ "${OS}" = "Darwin" ]; then
  apply_patch "${WORKDIR}/IMAS-MATLAB" "${PATCH_FILE}"
  apply_patch "${WORKDIR}/al-core" "${CORE_PATCH_FILE}"
  PATCH_SHA="$(shasum -a 256 "${PATCH_FILE}" | cut -d' ' -f1)"
  CORE_PATCH_SHA="$(shasum -a 256 "${CORE_PATCH_FILE}" | cut -d' ' -f1)"
fi

# --- build ------------------------------------------------------------------

CMAKE_OPTIONS=(
  -DCMAKE_BUILD_TYPE=RelWithDebInfo
  "-DCMAKE_INSTALL_PREFIX=${PREFIX}"
  "-DMatlab_ROOT_DIR=${MATLAB_ROOT}"
  -DAL_DEVELOPMENT_LAYOUT=ON
  -DAL_DOWNLOAD_DEPENDENCIES=OFF
  -DAL_BACKEND_HDF5=ON
  -DAL_BACKEND_MDSPLUS=OFF
  -DAL_BACKEND_UDA=OFF
  -DAL_PLUGINS=OFF
  -DAL_EXAMPLES=OFF
  -DAL_TESTS=OFF
  -DAL_PYTHON_BINDINGS=OFF
  -DAL_HLI_DOCS=OFF
  -DAL_DOCS_ONLY=OFF
)
[ -n "${CMAKE_PREFIX_PATH_VALUE}" ] && CMAKE_OPTIONS+=("-DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH_VALUE}")

log "Configuring"
cmake -S "${WORKDIR}/IMAS-MATLAB" -B "${WORKDIR}/build" "${CMAKE_OPTIONS[@]}"
log "Building with ${JOBS} jobs"
cmake --build "${WORKDIR}/build" --parallel "${JOBS}"
log "Installing into ${PREFIX}"
cmake --install "${WORKDIR}/build"

# --- manifest ---------------------------------------------------------------

json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }
describe() { git -C "$1" describe --tags --always 2>/dev/null || true; }
{
  printf '{\n'
  printf '  "created": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '  "vaft_matlab_revision": "%s",\n' "$(git -C "${REPO_ROOT}" rev-parse HEAD 2>/dev/null || true)"
  printf '  "platform": "%s",\n' "$(json_escape "$(uname -srm)")"
  printf '  "matlab_root": "%s",\n' "$(json_escape "${MATLAB_ROOT}")"
  printf '  "imas_matlab": {"source": "%s", "revision": "%s", "describe": "%s"},\n' \
    "$(json_escape "${MATLAB_SOURCE}")" "${MATLAB_REV}" "$(describe "${WORKDIR}/IMAS-MATLAB")"
  printf '  "imas_core": {"source": "%s", "revision": "%s", "describe": "%s"},\n' \
    "$(json_escape "${CORE_SOURCE}")" "${CORE_REV}" "$(describe "${WORKDIR}/al-core")"
  printf '  "data_dictionary": {"source": "%s", "revision": "%s", "describe": "%s"},\n' \
    "$(json_escape "${DD_SOURCE}")" "${DD_REV}" "$(describe "${WORKDIR}/data-dictionary")"
  printf '  "imas_matlab_macos_patch_sha256": "%s",\n' "${PATCH_SHA}"
  printf '  "imas_core_macos_patch_sha256": "%s",\n' "${CORE_PATCH_SHA}"
  printf '  "cmake_options": ['
  sep=""
  for opt in "${CMAKE_OPTIONS[@]}"; do printf '%s"%s"' "${sep}" "$(json_escape "${opt}")"; sep=", "; done
  printf ']\n}\n'
} > "${PREFIX}/${MANIFEST_NAME}"
log "Wrote ${PREFIX}/${MANIFEST_NAME}"

# --- acceptance -------------------------------------------------------------

if [ "${SKIP_TESTS}" -eq 0 ]; then
  run_acceptance
else
  log "Skipping acceptance tests (--skip-tests); the install is unverified."
fi

if [ "${KEEP_WORKDIR}" -eq 0 ]; then
  rm -rf "${WORKDIR}"
fi

log "Done. Start MATLAB with:"
log "  bash ${SCRIPT_DIR}/start_matlab.sh --prefix ${PREFIX}"
