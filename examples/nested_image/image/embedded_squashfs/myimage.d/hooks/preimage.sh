#!/bin/sh

set -eu

rootfs=$1
genimg_in=$2

sed -i "s|root=\([^ ]*\)|root=\/dev\/disk\/by-label\/ROOT|" ${rootfs}/boot/firmware/cmdline.txt

cat << EOF > ${rootfs}/etc/fstab
/dev/disk/by-label/ROOT /               ext4 rw,relatime,errors=remount-ro 0 1
/dev/disk/by-label/BOOT /boot/firmware  vfat rw,noatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,errors=remount-ro 0 2
/fw-store/firmware.squashfs /mnt/firmware squashfs ro,defaults,nofail 0 2
EOF


cp "$LAYER_DIR/ro_assets.cfg.in" ${genimg_in}/genimage01.cfg

FW_SIZE=150%
ROOT_SIZE=200%

WRITER=$(readlink -f writer.sh)

cat "$LAYER_DIR/main.cfg.in" | sed \
   -e "s|<IMAGE_DIR>|$IGconf_image_outputdir|g" \
   -e "s|<IMAGE_NAME>|$IGconf_image_name|g" \
   -e "s|<IMAGE_SUFFIX>|$IGconf_image_suffix|g" \
   -e "s|<FW_SIZE>|$FW_SIZE|g" \
   -e "s|<ROOT_SIZE>|$ROOT_SIZE|g" \
   -e "s|<EMBED_HOOK>|$WRITER|g" \
   > ${genimg_in}/genimage02.cfg
