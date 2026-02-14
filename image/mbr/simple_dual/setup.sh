#!/bin/bash

set -eu

LABEL="$1"
BOOTUUID="$2"
ROOTUUID="$3"

case $LABEL in
   ROOT)
      FSTABCONTENTS=$(<"$IMAGEMOUNTPATH/etc/fstab")
      case $IGconf_image_rootfs_type in
         ext4)
            cat << EOF > $IMAGEMOUNTPATH/etc/fstab
UUID=${ROOTUUID} /               ext4 rw,relatime,errors=remount-ro,commit=30 0 1
EOF
            ;;
         btrfs)
            cat << EOF > $IMAGEMOUNTPATH/etc/fstab
UUID=${ROOTUUID} /               btrfs defaults 0 0
EOF
            ;;
         *)
            ;;
      esac

      cat << EOF >> $IMAGEMOUNTPATH/etc/fstab
UUID=${BOOTUUID} /boot/firmware  vfat defaults,rw,noatime,errors=remount-ro 0 2
EOF
      echo $FSTABCONTENTS >> "$IMAGEMOUNTPATH/etc/fstab"
      ;;
   BOOT)
      sed -i "s|root=\([^ ]*\)|root=UUID=${ROOTUUID}|" $IMAGEMOUNTPATH/cmdline.txt
      ;;
   *)
      ;;
esac
