#!/bin/sh

set -eu

rootfs=$1
genimg_in=$2

FW_SIZE=100%
# 100% is minimal storage leaves no room for loading docker containers. 200% leaves overhead.
ROOT_SIZE=300%

cat genimage.cfg.in | sed \
   -e "s|<IMAGE_DIR>|$IGconf_image_outputdir|g" \
   -e "s|<IMAGE_NAME>|$IGconf_image_name|g" \
   -e "s|<IMAGE_SUFFIX>|$IGconf_image_suffix|g" \
   -e "s|<FW_SIZE>|$FW_SIZE|g" \
   -e "s|<ROOT_SIZE>|$ROOT_SIZE|g" \
   > ${genimg_in}/genimage.cfg
