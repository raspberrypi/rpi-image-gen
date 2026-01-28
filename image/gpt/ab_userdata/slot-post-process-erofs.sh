#!/bin/bash

set -u

COMP=$1

echo "pre-process $IMAGEMOUNTPATH for $COMP" 1>&2

case $COMP in
   SYSTEM)
      cat << EOF > $IMAGEMOUNTPATH/etc/fstab
/dev/disk/by-slot/active/system /              erofs defaults 0 1
/dev/disk/by-slot/active/boot   /boot/firmware vfat defaults,ro,noatime,nofail  0 2
LABEL=BOOTFS                    /bootfs        vfat defaults,rw,noatime,errors=panic 0 2

# Bespoke systemd generators mount /persistent, /var and bind mount into it
# for per-slot storage. See slot-perst-generator.

# home and journal persist across slots
/persistent/home         /home             none  bind,x-systemd.requires-mounts-for=/persistent/home,x-systemd.after=persistent.mount  0  0
/persistent/log/journal  /var/log/journal  none  bind,x-systemd.requires-mounts-for=/persistent/log/journal,x-systemd.after=persistent.mount  0  0
EOF
      ;;
   BOOT)
      sed -i "s|root=\([^ ]*\)|root=\/dev\/ram0|" $IMAGEMOUNTPATH/cmdline.txt
      ;;
   *)
      ;;
esac
