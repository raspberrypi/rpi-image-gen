#!/bin/bash

set -eu

fs=$1
genimg_in=$2


# Load pre-defined UUIDs
source "${IGconf_image_outputdir}/img_uuids"


# Settle the disk signature for PARTUUID derivation
# genimage resolves 'random' internally and never reports the value, so it must
# be concrete before genimage runs. Done here and not in customize because a
# first --image-only rebuild never runs customize at all. Reuse a signature an
# earlier run settled, so such a rebuild keeps the same PARTUUIDs.
SETTLED=${DISKSIG:-}
DISKSIG=$IGconf_image_disksig
if [[ $DISKSIG == random && $IGconf_image_rootdev_scheme == partuuid ]]; then
   if [[ $SETTLED =~ ^0x[0-9a-fA-F]{8}$ ]]; then
      DISKSIG=$SETTLED
   else
      # An all-zero signature yields PARTUUID=00000000-0N, which blkid does
      # not index
      DISKSIG=0x00000000
      while [[ $DISKSIG == 0x00000000 ]]; do
         DISKSIG="0x$(od -An -tx4 -N4 /dev/urandom | tr -d ' \n')"
      done
   fi
   # Only a signature settled here is recorded. A configured one is read from
   # the config every run, so recording it would let it outlive the config and
   # be reused by a later run that asked for random.
   sed -i '/^DISKSIG=/d' "${IGconf_image_outputdir}/img_uuids"
   echo "DISKSIG=$DISKSIG" >> "${IGconf_image_outputdir}/img_uuids"
fi


MKE2FS_ARGS_STR="-U $ROOT_UUID ${IGconf_fs_ext4_mkfs_args:-}"
BTRFS_ARGS_STR="-U $ROOT_UUID ${IGconf_fs_btrfs_mkfs_args:-}"
VFAT_ARGS_STR="-S $IGconf_device_sector_size -i $BOOT_LABEL ${IGconf_fs_vfat_mkfs_args:-}"


# Write genimage template
cat "$LAYER_DIR/genimage.cfg.in.$IGconf_image_rootfs_type" | sed \
   -e "s|<IMAGE_DIR>|$IGconf_image_outputdir|g" \
   -e "s|<IMAGE_NAME>|$IGconf_image_name|g" \
   -e "s|<IMAGE_SUFFIX>|$IGconf_image_suffix|g" \
   -e "s|<FW_SIZE>|$IGconf_image_boot_part_size|g" \
   -e "s|<ROOT_SIZE>|$IGconf_image_root_part_size|g" \
   -e "s|<SETUP>|'$(readlink -ef "$LAYER_DIR/setup.sh")'|g" \
   -e "s|<MKE2FS_CONF>|'$(readlink -ef "$LAYER_DIR/mke2fs.conf")'|g" \
   -e "s|<MKE2FS_EXTRAARGS>|$MKE2FS_ARGS_STR|g" \
   -e "s|<BTRFS_EXTRAARGS>|$BTRFS_ARGS_STR|g" \
   -e "s|<VFAT_EXTRAARGS>|$VFAT_ARGS_STR|g" \
   -e "s|<BOOT_UUID>|$BOOT_UUID|g" \
   -e "s|<ROOT_UUID>|$ROOT_UUID|g" \
   -e "s|<DISK_SIGNATURE>|$DISKSIG|g" \
   > ${genimg_in}/genimage.cfg
