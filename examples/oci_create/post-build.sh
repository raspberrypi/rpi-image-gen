#!/bin/bash

set -euo pipefail

fs="$1"

sde=$(< "${IGconf_target_dir}/SOURCE_DATE_EPOCH")
created=$(date -u -d @"${sde}" +%Y-%m-%dT%H:%M:%SZ)

org="raspberrypi"
dist="rpios"
flavour="trixie-slim"
arch="arm64"
tag="${arch}-${flavour}"

IMAGE_NAME="${org}/${dist}:${tag}"
MANIFEST_NAME="${org}/${dist}:${flavour}"

podman import \
     --change "LABEL org.opencontainers.image.architecture=${arch}" \
     --change 'LABEL org.opencontainers.image.vendor=Raspberry Pi Trading Ltd' \
     --change "LABEL org.opencontainers.image.title=${arch}-rpi-${dist}-${flavour}" \
     --change "LABEL org.opencontainers.image.description=Minimal base for ${arch}" \
     --change 'LABEL org.opencontainers.image.version=1.0' \
     --change "LABEL org.opencontainers.image.revision=${IGconf_artefact_version}" \
     --change "LABEL org.opencontainers.image.created=${created}" \
     --change 'LABEL org.opencontainers.image.url=https://www.raspberrypi.com' \
     --change 'LABEL org.opencontainers.image.authors=Raspberry Pi CI Team <applications@raspberrypi.com>' \
     --change 'CMD ["/bin/sh"]' \
     "$fs" "$IMAGE_NAME"

podman save --format oci-archive "$IMAGE_NAME" \
  | gzip -c > "${IGconf_target_dir}/oci-${arch}-rpi-${dist}-${flavour}.tar.gz"

podman image rm -f "$IMAGE_NAME"
