#!/bin/bash
# shellcheck disable=SC2154

set -eu

src=$(realpath -e "$1") || die "sbom: invalid src"
outdir=$(realpath -e "$2") || die "sbom: invalid outdir"

igconf isy sbom_enable || exit 0

[[ $(igconf getval sbom_provider) == syft ]] || exit 0

SYFTCFG=$(realpath -e $(igconf getval sbom_syft_config)) || die "Invalid syft config"

SYFT_VER=v1.32.0

# If host has syft, use it
if ! hash syft 2>/dev/null; then
   curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh \
      | sh -s -- -b "${IGconf_sys_workroot}/${DEB_BUILD_GNU_TYPE}/usr/bin" "${SYFT_VER}"
fi

SYFT=$(syft --version 2>/dev/null) || die "syft is unusable"

# Set properties based on scan target.
if [[ -f "$src" ]]; then
   scan_target="file:$src"
elif [[ -d "$src" ]]; then
   scan_target="dir:$src"
else
   die "sbom: '$src' is neither a file nor a directory"
fi

msg "\nSBOM: $SYFT scanning $scan_target"

syft -c "$SYFTCFG" "$scan_target" \
   --base-path "$src" \
   --source-name "$IGconf_sbom_name" \
   --source-version "$IGconf_sbom_version" \
   > "${outdir}/${IGconf_sbom_filename}"
