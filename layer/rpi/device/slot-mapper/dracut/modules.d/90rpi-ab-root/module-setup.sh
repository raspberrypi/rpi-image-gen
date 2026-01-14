#!/bin/bash
check() { return 0; }
depends() { echo "udev-rules"; }
install() {
   inst_binary /usr/bin/od
   inst_binary /usr/bin/sed
   inst_binary /usr/bin/rpi-slot-label
   inst_binary /usr/bin/rpi-slot-static
   inst_simple /boot/slot.map /boot/slot.map 2>/dev/null || :
   inst_rules /etc/udev/rules.d/99-rpi-slot.rules
   inst_hook pre-mount 50 "$moddir/root-check.sh"
}
