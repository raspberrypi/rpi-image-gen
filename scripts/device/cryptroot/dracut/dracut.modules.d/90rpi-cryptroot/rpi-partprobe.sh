#!/bin/sh
. /etc/rpi/cryptroot.conf
for dev in ${PARTPROBE_DEVICES-}; do
   if [ -e /dev/mapper/$dev ] ; then
     kpartx -av -p p /dev/mapper/$dev && udevadm settle
   fi
done
