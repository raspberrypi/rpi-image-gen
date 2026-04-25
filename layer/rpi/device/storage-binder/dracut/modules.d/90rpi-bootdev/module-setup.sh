#!/bin/bash
check() { return 0; }
depends() { echo "udev-rules"; }
install() {
   inst_binary /usr/bin/od
   inst_binary /usr/bin/rpi-bootdev-tag
   inst_rules /etc/udev/rules.d/99-rpi-00-bootdev.rules
}
