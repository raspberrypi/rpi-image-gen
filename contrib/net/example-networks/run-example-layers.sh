#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IG_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
IG_EXE="${IG_ROOT}/rpi-image-gen"

if [[ ! -x "${IG_EXE}" ]]; then
  echo "Error: rpi-image-gen executable not found at ${IG_EXE}" >&2
  exit 1
fi

declare -a EXAMPLES=(
  "deb-interfaces|v1-net-config|/etc/network/interfaces|iface eth0 inet static"
  "deb-netplan|v2-net-config|/etc/netplan/00-installer.yaml|ethernets:"
  "deb13-systemd-resolved|v3-net-config|/etc/systemd/network/01-eth0.network|DHCP=no"
)

failures=0
declare -a VERIFIED_LAYERS=()
declare -a VERIFIED_BUILD_ROOTS=()
declare -a VERIFIED_TARGET_PATHS=()
declare -a VERIFIED_FILES=()

extract_target_path() {
  local final_env="$1"
  sed -n 's/^IGconf_target_path="\(.*\)"$/\1/p' "$final_env" | head -n 1
}

run_one() {
  local example_dir="$1"
  local layer_name="$2"
  local expected_rel_path="$3"
  local expected_token="$4"

  local source_root="${SCRIPT_DIR}/${example_dir}"
  local example_build_root="${SCRIPT_DIR}/build/${example_dir}"
  local run_stamp
  local build_root
  local candidate_build_root
  local suffix
  local config_file
  local final_env

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
      candidate_build_root="${example_build_root}/run-${run_stamp}-$(printf '%02d' "${suffix}")"
      if [[ ! -e "${candidate_build_root}" ]]; then
        build_root="${candidate_build_root}"
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

  if ! "${IG_EXE}" build -f -S "${source_root}" -c "${config_file}" -B "${build_root}" -- IGconf_sbom_enable=n; then
    echo "[FAIL] ${layer_name}: build failed" >&2
    return 1
  fi

  if [[ ! -f "${final_env}" ]]; then
    echo "[FAIL] ${layer_name}: missing bootstrap final.env at ${final_env}" >&2
    return 1
  fi

  local target_path
  target_path="$(extract_target_path "${final_env}")"

  if [[ -z "${target_path}" || ! -d "${target_path}" ]]; then
    echo "[FAIL] ${layer_name}: target filesystem path not resolved from final.env" >&2
    return 1
  fi

  # Guard against non-isolated outputs by ensuring each run stays inside run-XXXXXX.
  if [[ "${target_path}" != "${build_root}/"* ]]; then
    echo "[FAIL] ${layer_name}: target filesystem path is not inside run workroot" >&2
    echo "[FAIL] ${layer_name}: workroot=${build_root}" >&2
    echo "[FAIL] ${layer_name}: target_path=${target_path}" >&2
    return 1
  fi

  local expected_file="${target_path}${expected_rel_path}"

  if [[ ! -f "${expected_file}" ]]; then
    echo "[FAIL] ${layer_name}: expected file not found: ${expected_file}" >&2
    return 1
  fi

  if ! grep -Fq "${expected_token}" "${expected_file}"; then
    echo "[FAIL] ${layer_name}: expected content token missing (${expected_token}) in ${expected_file}" >&2
    return 1
  fi

  VERIFIED_LAYERS+=("${layer_name}")
  VERIFIED_BUILD_ROOTS+=("${build_root}")
  VERIFIED_TARGET_PATHS+=("${target_path}")
  VERIFIED_FILES+=("${expected_file}")

  echo "[PASS] ${layer_name}: verified ${expected_rel_path}"
  return 0
}

for row in "${EXAMPLES[@]}"; do
  IFS='|' read -r example_dir layer_name expected_rel_path expected_token <<< "${row}"
  if ! run_one "${example_dir}" "${layer_name}" "${expected_rel_path}" "${expected_token}"; then
    failures=$((failures + 1))
  fi
  echo
done

if [[ "${failures}" -ne 0 ]]; then
  echo "Completed with ${failures} failure(s)." >&2
  exit 1
fi

echo ""
echo "Verified target file listings:"
for i in "${!VERIFIED_FILES[@]}"; do
  file_path="${VERIFIED_FILES[$i]}"
  dir_path="$(dirname "${file_path}")"
  echo "- ${VERIFIED_LAYERS[$i]}"
  echo "  workroot: ${VERIFIED_BUILD_ROOTS[$i]}"
  echo "  target filesystem: ${VERIFIED_TARGET_PATHS[$i]}"
  echo "  directory: ${dir_path}"
  ls -ld "${dir_path}"
  ls -l "${file_path}"
done

echo "Completed successfully: all 3 builds passed and README-described files were verified."
