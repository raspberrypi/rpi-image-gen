#!/bin/bash

set -eu

fs=$1
genimg_in=$2

[[ -d "$fs" ]] || exit 0


# Generate pre-defined UUIDs
BOOT_LABEL=$(uuidgen | sed 's/-.*//' | tr 'a-f' 'A-F')
BOOT_UUID=$(echo "$BOOT_LABEL" | sed 's/^\(....\)\(....\)$/\1-\2/')
ROOT_UUID=$(uuidgen)
CRYPT_UUID=$(uuidgen)

rm -f ${IGconf_image_outputdir}/img_uuids
for v in BOOT_LABEL BOOT_UUID ROOT_UUID CRYPT_UUID; do
    eval "val=\$$v"
    echo "$v=$val" >> "${IGconf_image_outputdir}/img_uuids"
done

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


# Install provision map and populate UUIDs
pmap="${IGconf_image_assetdir:-}/device/provisionmap-${IGconf_image_pmap:-}.json"
if [ -f "$pmap" ]; then
   env CRYPT_UUID="$CRYPT_UUID" \
      envsubst '${CRYPT_UUID}' < "$pmap" > "${IGconf_image_outputdir}/provisionmap.json"
fi
