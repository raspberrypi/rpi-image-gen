#!/bin/bash

set -euo pipefail

sde=$(< "${IGconf_target_dir}/SOURCE_DATE_EPOCH")
created=$(date -u -d @"${sde}" +%Y-%m-%dT%H:%M:%SZ)

org="raspberrypi"
dist="rpios"
flavour="trixie-slim"
arch="arm64"
tag="${arch}-${flavour}"

IMAGE_NAME="${org}/${dist}:${tag}"
MANIFEST_NAME="${org}/${dist}:${flavour}"

IMAGE_ID=$(podman import \
     --change "LABEL org.opencontainers.image.architecture=${arch}" \
     --change 'LABEL org.opencontainers.image.vendor=Raspberry Pi Trading Ltd' \
     --change "LABEL org.opencontainers.image.created=${created}" \
     --change 'LABEL org.opencontainers.image.url=https://www.raspberrypi.com' \
     --change 'LABEL org.opencontainers.image.authors=Raspberry Pi CI Team <applications@raspberrypi.com>' \
     --change 'ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]' \
     --change 'CMD ["/bin/bash"]' \
     "$1" "$IMAGE_NAME")

podman save --format docker-archive "$IMAGE_NAME" \
  | gzip -c > "${IGconf_target_dir}/docker-${arch}-rpi-${dist}-${flavour}.tar.gz"

# Can hook up Docker push/add flow here, eg set up for multi-arch via manifest
# podman manifest create --amend "$MANIFEST_NAME"
# podman manifest add "$MANIFEST_NAME" ...

# Cleaning up here removes the image from the local store which will break
# anything that assumes it's there.
podman image rm -f "$IMAGE_NAME"
