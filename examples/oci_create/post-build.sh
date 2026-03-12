#!/bin/bash

set -eu

fs="$1"

sde=$(< "${IGconf_target_dir}/SOURCE_DATE_EPOCH")
created=$(date -u -d @"${sde}" +%Y-%m-%dT%H:%M:%SZ)

podman import \
     --change 'LABEL org.opencontainers.image.vendor=Raspberry Pi Trading Ltd' \
     --change 'LABEL org.opencontainers.image.title=arm64-rpi-trixie-slim' \
     --change 'LABEL org.opencontainers.image.description=Minimal base for arm64' \
     --change 'LABEL org.opencontainers.image.version=1.0' \
     --change "LABEL org.opencontainers.image.revision=${IGconf_artefact_version}" \
     --change "LABEL org.opencontainers.image.created=${created}" \
     --change 'LABEL org.opencontainers.image.url=https://www.raspberrypi.com' \
     --change 'LABEL org.opencontainers.image.authors=Raspberry Pi CI Team <applications@raspberrypi.com>' \
     --change 'CMD ["/bin/sh"]' \
     "$fs" rpi:arm64-trixie-slim

podman save --format oci-archive rpi:arm64-trixie-slim \
  | gzip -c > ${IGconf_target_dir}/arm64-rpi-trixie-slim.oci.tar.gz

podman image rm -f rpi:arm64-trixie-slim
