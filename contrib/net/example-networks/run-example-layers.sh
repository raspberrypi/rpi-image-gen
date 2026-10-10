#!/usr/bin/env bash
#
# Build each example network layer on top of trixie-minbase for a Pi 5 and
# verify the resulting filesystem, not just the checked-in reference files.
#
# Usage:
#   ./run-example-layers.sh [example ...] [-- IGconf_key=value ...]
#
#   example   One or more of: deb-interfaces deb-netplan deb13-systemd-resolved
#             Defaults to all three.
#   --        Anything after it is passed to 'rpi-image-gen build' as a
#             variable override, eg IGconf_net_addr=10.0.0.5/24
#
# Each run gets its own time-stamped work root under build/<example>/ so
# results never overlap. Note that rpi-image-gen compiles its host tools
# (bdebstrap, genimage, zstd) into every new work root, so each run pays that
# cost once before the filesystem build starts.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IG_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
IG_EXE="${IG_ROOT}/rpi-image-gen"

if [[ ! -x "${IG_EXE}" ]]; then
  echo "Error: rpi-image-gen executable not found at ${IG_EXE}" >&2
  exit 1
fi

declare -A LAYER_OF=(
  [deb-interfaces]=v1-net-config
  [deb-netplan]=v2-net-config
  [deb13-systemd-resolved]=v3-net-config
)
declare -a DEFAULT_ORDER=(deb-interfaces deb-netplan deb13-systemd-resolved)

# Split arguments into example names and build overrides.
declare -a SELECTED=()
declare -a OVERRIDES=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --) shift; OVERRIDES=("$@"); break ;;
    *)
      if [[ -z "${LAYER_OF[$1]:-}" ]]; then
        echo "Error: unknown example '$1'. Choose from: ${DEFAULT_ORDER[*]}" >&2
        exit 1
      fi
      SELECTED+=("$1"); shift ;;
  esac
done
[[ ${#SELECTED[@]} -eq 0 ]] && SELECTED=("${DEFAULT_ORDER[@]}")

failures=0
declare -a VERIFIED_LAYERS=()
declare -a VERIFIED_BUILD_ROOTS=()
declare -a VERIFIED_FILES=()

# --- Checks run against the built filesystem ---------------------------------
# Each takes the target root in $TARGET and appends to CHECK_ERRORS on failure.
declare -a CHECK_ERRORS=()
TARGET=""

need_file() {
  [[ -f "${TARGET}$1" ]] || CHECK_ERRORS+=("missing file $1")
}

need_absent() {
  [[ ! -e "${TARGET}$1" ]] || CHECK_ERRORS+=("file $1 should not exist")
}

need_token() {
  local file="$1" token="$2"
  [[ -f "${TARGET}${file}" ]] || { CHECK_ERRORS+=("missing file ${file}"); return; }
  grep -Fq -- "${token}" "${TARGET}${file}" \
    || CHECK_ERRORS+=("token '${token}' not found in ${file}")
}

need_mode() {
  local file="$1" mode="$2" actual
  [[ -f "${TARGET}${file}" ]] || return
  actual="$(stat -c '%a' "${TARGET}${file}")"
  [[ "${actual}" == "${mode}" ]] \
    || CHECK_ERRORS+=("${file} has mode ${actual}, expected ${mode}")
}

need_pkg() {
  local pkg="$1" status
  if command -v dpkg-query >/dev/null 2>&1; then
    status="$(dpkg-query --admindir="${TARGET}/var/lib/dpkg" -W -f='${Status}' "${pkg}" 2>/dev/null || true)"
    [[ "${status}" == *"install ok installed"* ]] \
      || CHECK_ERRORS+=("package ${pkg} is not installed (status: '${status:-absent}')")
  else
    grep -q "^Package: ${pkg}\$" "${TARGET}/var/lib/dpkg/status" \
      || CHECK_ERRORS+=("package ${pkg} is not installed")
  fi
}

need_enabled() {
  # Enabled units are symlinked from some <target>.wants/ directory.
  local unit="$1"
  find "${TARGET}/etc/systemd/system" -path "*.wants/${unit}" -type l 2>/dev/null | grep -q . \
    || CHECK_ERRORS+=("unit ${unit} is not enabled")
}

verify_deb_interfaces() {
  need_pkg ifupdown
  need_enabled networking.service
  need_token /etc/network/interfaces "iface eth0 inet static"
  need_token /etc/network/interfaces "dns-nameservers"
  # eth0 must be handed over from systemd-networkd to ifupdown.
  need_token /etc/systemd/network/01-eth0.network "Unmanaged=yes"
}

verify_deb_netplan() {
  need_pkg netplan.io
  need_token /etc/netplan/00-installer.yaml "renderer: networkd"
  need_token /etc/netplan/00-installer.yaml "dhcp4: false"
  need_mode  /etc/netplan/00-installer.yaml 600
  # The DHCP unit from rpi-device-base would sort before Netplan's output.
  need_absent /etc/systemd/network/01-eth0.network
}

verify_deb13_systemd_resolved() {
  need_enabled systemd-networkd.service
  need_enabled systemd-resolved.service
  need_token /etc/systemd/network/01-eth0.network "DHCP=no"
  need_token /etc/systemd/network/01-eth0.network "Address="
  need_token /etc/systemd/network/01-eth0.network "DNS="
}

# --- Build driver -------------------------------------------------------------

extract_target_path() {
  local final_env="$1"
  sed -n 's/^IGconf_target_path="\(.*\)"$/\1/p' "${final_env}" | head -n 1
}

run_one() {
  local example_dir="$1"
  local layer_name="${LAYER_OF[$example_dir]}"
  local source_root="${SCRIPT_DIR}/${example_dir}"
  local example_build_root="${SCRIPT_DIR}/build/${example_dir}"
  local run_stamp build_root candidate suffix config_file final_env

  echo "[BUILD] ${layer_name} (${example_dir})"

  if [[ ! -d "${source_root}/layer" ]]; then
    echo "[FAIL] ${layer_name}: missing source layer directory at ${source_root}/layer" >&2
    return 1
  fi

  mkdir -p "${example_build_root}"
  run_stamp="$(date +%y%m%d%H%M)"
  build_root="${example_build_root}/run-${run_stamp}"

  # Keep run directories sortable by time. Add a numeric suffix only if this minute already exists.
  if [[ -e "${build_root}" ]]; then
    suffix=1
    while :; do
      candidate="${example_build_root}/run-${run_stamp}-$(printf '%02d' "${suffix}")"
      if [[ ! -e "${candidate}" ]]; then
        build_root="${candidate}"
        break
      fi
      suffix=$((suffix + 1))
    done
  fi

  mkdir -p "${build_root}"
  config_file="${build_root}/config.yaml"
  final_env="${build_root}/bootstrap/final.env"

  echo "[INFO] ${layer_name}: workroot ${build_root}"

  cat > "${config_file}" <<CFG
device:
  layer: rpi5

image:
  layer: image-rpios
  name: example-${layer_name}

layer:
  base: trixie-minbase
  network: ${layer_name}
CFG

  # -f builds the filesystem only; no image is produced. SBOM generation is
  # switched off because it adds time and is irrelevant to these checks.
  if ! "${IG_EXE}" build -f -S "${source_root}" -c "${config_file}" -B "${build_root}" \
        -- IGconf_sbom_enable=n "${OVERRIDES[@]}"; then
    echo "[FAIL] ${layer_name}: build failed" >&2
    return 1
  fi

  if [[ ! -f "${final_env}" ]]; then
    echo "[FAIL] ${layer_name}: missing bootstrap final.env at ${final_env}" >&2
    return 1
  fi

  TARGET="$(extract_target_path "${final_env}")"

  if [[ -z "${TARGET}" || ! -d "${TARGET}" ]]; then
    echo "[FAIL] ${layer_name}: target filesystem path not resolved from final.env" >&2
    return 1
  fi

  # Guard against non-isolated outputs by ensuring each run stays inside its workroot.
  if [[ "${TARGET}" != "${build_root}/"* ]]; then
    echo "[FAIL] ${layer_name}: target filesystem path is not inside run workroot" >&2
    echo "[FAIL] ${layer_name}: workroot=${build_root}" >&2
    echo "[FAIL] ${layer_name}: target_path=${TARGET}" >&2
    return 1
  fi

  CHECK_ERRORS=()
  "verify_${example_dir//-/_}"

  if [[ ${#CHECK_ERRORS[@]} -ne 0 ]]; then
    local err
    for err in "${CHECK_ERRORS[@]}"; do
      echo "[FAIL] ${layer_name}: ${err}" >&2
    done
    return 1
  fi

  VERIFIED_LAYERS+=("${layer_name}")
  VERIFIED_BUILD_ROOTS+=("${build_root}")
  VERIFIED_FILES+=("${TARGET}")

  echo "[PASS] ${layer_name}: filesystem checks passed"
  return 0
}

for example_dir in "${SELECTED[@]}"; do
  if ! run_one "${example_dir}"; then
    failures=$((failures + 1))
  fi
  echo
done

if [[ "${failures}" -ne 0 ]]; then
  echo "Completed with ${failures} failure(s)." >&2
  exit 1
fi

echo "Verified filesystems:"
for i in "${!VERIFIED_LAYERS[@]}"; do
  echo "- ${VERIFIED_LAYERS[$i]}"
  echo "  workroot:          ${VERIFIED_BUILD_ROOTS[$i]}"
  echo "  target filesystem: ${VERIFIED_FILES[$i]}"
done

echo "Completed successfully: ${#VERIFIED_LAYERS[@]} build(s) passed."
