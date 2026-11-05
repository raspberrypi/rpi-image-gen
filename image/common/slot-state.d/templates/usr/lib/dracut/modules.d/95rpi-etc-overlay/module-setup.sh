#!/bin/bash
check() { return 0; }
depends() { echo "systemd"; }
installkernel() { instmods overlay; }
install() {
   inst_multiple rsync sed
   inst_script "$moddir/rpi-etc-overlay.sh" /usr/libexec/rpi-etc-overlay
   inst_simple "$moddir/rpi-etc-overlay.service" "$systemdsystemunitdir/rpi-etc-overlay.service"
   $SYSTEMCTL -q --root "$initdir" add-wants initrd-fs.target rpi-etc-overlay.service
}
