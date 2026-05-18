#!/bin/bash

set -eu

: "${1:?chroot path not set}"
: "${PARTPROBE_DEVICES?not set}"
: "${CRYPT_CONTAINERS_FILE:?not set}"


# Auto-generate crypttab if not present
if [[ ! -f "${1}/etc/crypttab" ]] || ! grep -qvE '^\s*(#|$)' "${1}/etc/crypttab"; then
  source $CRYPT_CONTAINERS_FILE

  for container in "$CONTAINERS"; do
     eval "label=\$${container}_LABEL"
     eval "name=\$${container}_MNAME"
     echo "$name LABEL=$label none luks"
  done > "$1/etc/crypttab"
fi


rsync -av dracut/dracut.modules.d/ "$1/usr/lib/dracut/modules.d/"
rsync -av dracut/dracut.conf.d/ "$1/etc/dracut.conf.d/"

mkdir -p "$1/etc/rpi/"
echo "PARTPROBE_DEVICES=\"${PARTPROBE_DEVICES}\"" \
   > "$1/etc/rpi/cryptroot.conf"
