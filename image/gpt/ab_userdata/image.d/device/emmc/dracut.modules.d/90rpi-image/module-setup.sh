#!/bin/bash
check() { return 0; }
depends() { return 0; }
install() {
   inst_binary /usr/bin/mmc
   inst_hook pre-pivot 90 "$moddir/emmc-wp.sh"
}
