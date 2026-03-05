#!/bin/sh

case $1 in
   prereqs)
      echo ""
      exit 0
      ;;
esac

. /scripts/functions

set -e

DEV=/dev/mmcblk0

# GPT entries begin at +8M. Write Protect everything prior.
PROT_SZ_KB=$((8 * 1024))

CSD=$(mmc extcsd read "$DEV")
ERASE_GRP_SZ=$(echo "$CSD" | sed -n 's/.*HC_ERASE_GRP_SIZE *: *0x\([0-9A-Fa-f]*\).*/\1/p')
WP_GRP_SZ=$(echo "$CSD" | sed -n 's/.*HC_WP_GRP_SIZE *: *0x\([0-9A-Fa-f]*\).*/\1/p')

# Num erase groups per HC erase unit
ERASE_GRP_SZ=$((0x$ERASE_GRP_SZ))

# Num erase groups per WP group
WP_GRP_SZ=$((0x$WP_GRP_SZ))

# Each erase group is 512KB
WP_GRP_SZ_KB=$((WP_GRP_SZ * ERASE_GRP_SZ * 512))

# Num WP groups to protect region
WP_NUM_GRP=$(( (PROT_SZ_KB + WP_GRP_SZ_KB - 1) / WP_GRP_SZ_KB))

# Num blocks to protect region
WP_NUM_BLK=$((WP_NUM_GRP * WP_GRP_SZ_KB * 2))

echo "WP $ERASE_GRP_SZ $WP_GRP_SZ $WP_GRP_SZ_KB $WP_NUM_GRP $WP_NUM_BLK"

# Device geom dictates the min size that can be protected. The protection
# applied must not overrun.
WP_BYTES=$((WP_NUM_BLK * 512))
PROT_SZ_BYTES=$((PROT_SZ_KB * 1024))
if [ "$WP_BYTES" -ne "$PROT_SZ_BYTES" ] ; then
   >&2 echo "WP overrun $PROT_SZ_KB"
   exit 1
fi
mmc writeprotect user set pwron 0 $WP_NUM_BLK $DEV
