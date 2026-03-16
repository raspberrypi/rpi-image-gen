#!/bin/bash

set -eu

sde=$(< "${IGconf_target_dir}/SOURCE_DATE_EPOCH")
created=$(date -u -d @"${sde}" +%Y-%m-%dT%H:%M:%SZ)

podman import \
     --change 'LABEL org.opencontainers.image.vendor=Raspberry Pi Trading Ltd' \
     --change "LABEL org.opencontainers.image.created=${created}" \
     --change 'LABEL org.opencontainers.image.url=https://www.raspberrypi.com' \
     --change 'LABEL org.opencontainers.image.authors=Raspberry Pi CI Team <applications@raspberrypi.com>' \
     --change 'ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]' \
     --change 'CMD ["/bin/bash"]' \
     "$1" rpi:arm64-trixie-slim

podman save --format docker-archive rpi:arm64-trixie-slim \
  | gzip -c > ${IGconf_target_dir}/docker-arm64-rpi-trixie-slim.tar.gz

podman image rm -f rpi:arm64-trixie-slim
