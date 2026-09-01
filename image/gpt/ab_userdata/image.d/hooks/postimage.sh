#!/bin/bash

set -eu

upd="${1}/update"
rm -rf $upd
mkdir -p $upd

[[ -f ${1}/system.sparse ]] || false
[[ -f ${1}/boot.sparse ]] || false

ln -sf ../system.sparse ${upd}/system
ln -sf ../boot.sparse ${upd}/boot

msg "Packing..."
cd $upd && tar -I zstd -h -cf  ${1}/update.tar.zst -- *
