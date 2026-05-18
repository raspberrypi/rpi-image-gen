#!/bin/bash

set -eu

fs=$1
genimg_in=$2


# Load pre-defined UUIDs
source "${IGconf_image_outputdir}/img_uuids"


MKE2FS_ARGS_STR="-U $ROOT_UUID ${IGconf_fs_ext4_mkfs_args:-}"
BTRFS_ARGS_STR="-U $ROOT_UUID ${IGconf_fs_btrfs_mkfs_args:-}"
VFAT_ARGS_STR="-S $IGconf_device_sector_size -i $BOOT_LABEL ${IGconf_fs_vfat_mkfs_args:-}"


# Write genimage template
cat genimage.cfg.in.$IGconf_image_rootfs_type | sed \
   -e "s|<IMAGE_DIR>|$IGconf_image_outputdir|g" \
   -e "s|<IMAGE_NAME>|$IGconf_image_name|g" \
   -e "s|<IMAGE_SUFFIX>|$IGconf_image_suffix|g" \
   -e "s|<FW_SIZE>|$IGconf_image_boot_part_size|g" \
   -e "s|<ROOT_SIZE>|$IGconf_image_root_part_size|g" \
   -e "s|<SETUP>|'$(readlink -ef setup.sh)'|g" \
   -e "s|<MKE2FS_CONF>|'$(readlink -ef mke2fs.conf)'|g" \
   -e "s|<MKE2FS_EXTRAARGS>|$MKE2FS_ARGS_STR|g" \
   -e "s|<BTRFS_EXTRAARGS>|$BTRFS_ARGS_STR|g" \
   -e "s|<VFAT_EXTRAARGS>|$VFAT_ARGS_STR|g" \
   -e "s|<BOOT_UUID>|$BOOT_UUID|g" \
   -e "s|<ROOT_UUID>|$ROOT_UUID|g" \
   > ${genimg_in}/genimage.cfg
