#!/bin/sh

set -eu

rootfs=$1
genimg_in=$2

# Set up the partition layout for tryboot support. Partition numbering
# relates directly to the layout in genimage.cfg.in

cat << EOF > "${genimg_in}/autoboot.txt"
[all]
tryboot_a_b=1
boot_partition=2
[tryboot]
boot_partition=3
EOF

# Generate the config for genimage to ingest:
# FIXME - sizes should be easily configurable
FW_SIZE=125%
ROOT_SIZE=200%

SLOTP_PROCESS=$(readlink -f slot-post-process.sh)

cat genimage.cfg.in | sed \
   -e "s|<IMAGE_DIR>|$IGconf_image_outputdir|g" \
   -e "s|<IMAGE_NAME>|$IGconf_image_name|g" \
   -e "s|<IMAGE_SUFFIX>|$IGconf_image_suffix|g" \
   -e "s|<FW_SIZE>|$FW_SIZE|g" \
   -e "s|<ROOT_SIZE>|$ROOT_SIZE|g" \
   -e "s|<SLOTP>|'$SLOTP_PROCESS'|g" \
   > ${genimg_in}/genimage.cfg
