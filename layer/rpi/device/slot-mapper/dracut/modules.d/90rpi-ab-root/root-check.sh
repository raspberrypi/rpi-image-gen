#!/bin/sh
path=/dev/disk/by-slot/active/system
if [ ! -b "$path" ]; then
   echo "FATAL: AB missing $path - rebooting" > /dev/kmsg
   reboot -f || echo b > /proc/sysrq-trigger
fi
