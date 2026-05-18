#!/bin/bash

set -eu

LABEL="$1"

case $LABEL in
   ROOT)
      case $IGconf_image_rootfs_type in
         ext4)
            cat << EOF > $IMAGEMOUNTPATH/etc/fstab
/dev/disk/by-slot/system  /  ext4 rw,relatime,errors=remount-ro,commit=30 0 1
EOF
            ;;
         btrfs)
            cat << EOF > $IMAGEMOUNTPATH/etc/fstab
/dev/disk/by-slot/system  /  btrfs defaults 0 0
EOF
            ;;
         *)
            ;;
      esac

      cat << EOF >> $IMAGEMOUNTPATH/etc/fstab
/dev/disk/by-slot/boot  /boot/firmware  vfat defaults,rw,noatime,errors=remount-ro 0 2
EOF
      ;;
   BOOT)
      sed -i "s|root=\([^ ]*\)|root=/dev/disk/by-slot/system|" $IMAGEMOUNTPATH/cmdline.txt
      ;;
   *)
      ;;
esac
