#!/bin/sh

export "PATH=/usr/sbin:$PATH"

case $1 in
   prereqs) echo ""; exit 0;;
esac

. /scripts/functions

# Set root on active slot
path=/dev/disk/by-slot/active/system
if [ ! -b "$path" ]; then
   msg="FATAL: AB missing $path - rebooting"
   if [ -w /dev/kmsg ]; then
      echo "$msg" > /dev/kmsg 2>/dev/null || :
   fi
   echo "$msg" >&2
   reboot -f 2>/dev/null || echo b > /proc/sysrq-trigger
fi

echo "ROOT=$path" >> /conf/param.conf
log_success_msg "AB: delegated $path"
