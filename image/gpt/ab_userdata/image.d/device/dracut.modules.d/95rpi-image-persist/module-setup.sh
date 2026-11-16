#!/bin/bash
check() { return 0; }
depends() { echo "systemd udev-rules"; }
install() {
   inst_rules /etc/udev/rules.d/99-rpi-05-image.rules
   inst_script /usr/lib/systemd/system-generators/slot-perst-generator \
      "${systemdutildir}/system-generators/slot-perst-generator"
   inst_multiple systemd-escape e2fsck fsck.ext4 \
      "${systemdutildir}/systemd-fsck" "${systemdsystemunitdir}/systemd-fsck@.service"
}
