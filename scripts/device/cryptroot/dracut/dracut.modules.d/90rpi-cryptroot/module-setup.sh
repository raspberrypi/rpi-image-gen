#!/bin/bash
check() { return 0; }
depends() { echo crypt; return 0; }
install() {
   inst_simple /etc/rpi/cryptroot.conf
   . /etc/rpi/cryptroot.conf

   if [ -n "${PARTPROBE_DEVICES-}" ]; then
      inst_multiple /usr/sbin/kpartx
      inst_hook initqueue/settled 90 "$moddir/rpi-partprobe.sh"
   fi

   inst "$systemdsystemunitdir/cryptsetup-passphrase-agent.service"
   inst "$systemdsystemunitdir/cryptsetup-passphrase-agent.path"

   $SYSTEMCTL -q --root "$initdir" add-wants sysinit.target cryptsetup-passphrase-agent.path
}
