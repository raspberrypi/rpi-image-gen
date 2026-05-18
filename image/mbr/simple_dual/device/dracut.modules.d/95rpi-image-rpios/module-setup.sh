#!/bin/bash
check() { return 0; }
depends() { echo "udev-rules"; }
install() {
   inst_rules /etc/udev/rules.d/99-rpi-05-image.rules
}
