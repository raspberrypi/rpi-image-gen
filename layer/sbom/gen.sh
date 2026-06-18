#!/bin/bash
# shellcheck disable=SC2154

set -eu

outdir=$(realpath -e "$2") || die "sbom: invalid outdir"

igconf isy sbom_enable || exit 0

[[ $(igconf getval sbom_provider) == syft ]] || exit 0

SYFTCFG=$(igconf getval sbom_syft_config)

SYFT_VER=v1.44.0  # leave empty to install latest

# If host has syft, use it
if ! hash syft 2>/dev/null; then
   curl -sSfL https://get.anchore.io/syft \
      | sh -s -- -b "${IGconf_sys_workroot}/${DEB_BUILD_GNU_TYPE}/usr/bin" ${SYFT_VER:+"$SYFT_VER"}
fi

SYFT=$(syft --version 2>/dev/null) || die "syft is unusable"

spec=
scan_args=()
scan_target=


# Set up source or auto-detect if none specified
if spec=$(igconf getval sbom_syft_source 2>/dev/null) && [[ -n "$spec" ]]; then
   case "$spec" in
      podman:*|docker:*)
         scan_args+=( "--scope" "all-layers" )
         scan_target="$spec"
         ;;
      oci-archive:*)
         scan_target="$spec"
         ;;
      dir:*)
         target=${spec#dir:}
         scan_target="$target"
         scan_args+=( "--base-path" "$target" )
         ;;
      *)
         resolved=$(map_path "$spec") || die "sbom: cannot resolve '$spec'"
         if [[ -d $resolved ]]; then
            scan_target="dir:$resolved"
            scan_args+=( --base-path "$resolved" )
         elif [[ -f $resolved ]]; then
            case "$resolved" in
               *.oci.tar|*.oci) scan_target="oci-archive:$resolved" ;;
               *)               scan_target="file:$resolved" ;;
            esac
         else
            die "sbom: resolved path '$resolved' non-existent"
         fi
         ;;
   esac
else
   target=$(realpath -e "$IGconf_target_path") || die "sbom: non-existent target"
   if [[ -f "$target" ]]; then
      scan_target="file:$target"
   elif [[ -d "$target" ]]; then
      scan_args+=( "--base-path" "$target" )
      scan_target="dir:$target"
   else
      die "sbom: '$target' is neither a file nor a directory"
   fi
fi


msg "$SYFT scanning $scan_target ${scan_args[*]}"

syft -c "$SYFTCFG" "$scan_target" "${scan_args[@]}" \
   --source-name "$IGconf_sbom_name" \
   --source-version "$IGconf_sbom_version" \
   > "${outdir}/${IGconf_sbom_filename}"
