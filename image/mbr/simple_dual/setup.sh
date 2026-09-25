#!/bin/bash

set -eu

LABEL="$1"

case $IGconf_image_rootdev_scheme in
   partuuid)
      # A configured signature is authoritative; only a settled one is recorded
      # by preimage.sh - see the note there
      DISKSIG=$IGconf_image_disksig
      if [[ $DISKSIG == random ]]; then
         source "${IGconf_image_outputdir}/img_uuids"
      fi
      [[ ${DISKSIG:-} =~ ^0x[0-9a-fA-F]{8}$ ]] || { echo "setup: unresolved disk signature '${DISKSIG:-unset}'" >&2; exit 1; }
      SIG=${DISKSIG#0x}
      SIG=${SIG,,}
      BOOTDEV="PARTUUID=${SIG}-01"
      ROOTDEV="PARTUUID=${SIG}-02"
      ;;
   *)
      BOOTDEV=/dev/disk/by-slot/boot
      ROOTDEV=/dev/disk/by-slot/system
      ;;
esac

case $LABEL in
   ROOT)
      case $IGconf_image_rootfs_type in
         ext4)
            cat << EOF > $IMAGEMOUNTPATH/etc/fstab
$ROOTDEV  /  ext4 rw,relatime,errors=remount-ro,commit=30 0 1
EOF
            ;;
         btrfs)
            cat << EOF > $IMAGEMOUNTPATH/etc/fstab
$ROOTDEV  /  btrfs defaults 0 0
EOF
            ;;
         *)
            ;;
      esac

      cat << EOF >> $IMAGEMOUNTPATH/etc/fstab
$BOOTDEV  /boot/firmware  vfat defaults,rw,noatime,errors=remount-ro 0 2
EOF
      ;;
   BOOT)
      sed -i "s|root=[^ ]*|root=$ROOTDEV|" $IMAGEMOUNTPATH/cmdline.txt
      ;;
   *)
      ;;
esac
