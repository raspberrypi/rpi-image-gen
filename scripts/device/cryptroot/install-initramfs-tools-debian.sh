#!/bin/bash
# initramfs-tools cryptroot installer (debian)

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
     echo "$name LABEL=$label none luks,initramfs,keyscript=/lib/cryptsetup/keyscripts/hwkey"
  done > "$1/etc/crypttab"
fi


install -m 0755 -D hwkey "$1/lib/cryptsetup/keyscripts/hwkey"
rsync -av initramfs-tools/ "$1/etc/initramfs-tools/"


echo "PARTPROBE_DEVICES=\"${PARTPROBE_DEVICES}\"" \
   > "$1/etc/initramfs-tools/conf.d/rpi-cryptroot"
