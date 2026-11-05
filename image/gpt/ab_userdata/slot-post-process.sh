#!/bin/bash

set -u

COMP=$1

echo "pre-process $IMAGEMOUNTPATH for $COMP" 1>&2

case $COMP in
   SYSTEM)
      # type select
      case $IGconf_image_rootfs_type in
         ext4)
            cat << EOF > $IMAGEMOUNTPATH/etc/fstab
/dev/disk/by-slot/active/system /              ext4 ro,relatime,commit=30 0 1
EOF
            ;;
         erofs)
            cat << EOF > $IMAGEMOUNTPATH/etc/fstab
/dev/disk/by-slot/active/system /              erofs defaults 0 0
EOF
            ;;
      esac

      # remainder is constant
      cat << EOF >> $IMAGEMOUNTPATH/etc/fstab
/dev/disk/by-slot/active/boot  /boot/firmware  vfat defaults,ro,noatime,nofail  0 2
/dev/disk/by-slot/bootconfig   /bootfs         vfat defaults,rw,noatime,nofail 0 2

# A systemd generator mounts /persistent. See slot-perst-generator.
EOF
      ;;
   *)
      ;;
esac
