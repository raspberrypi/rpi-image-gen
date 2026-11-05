#!/bin/sh
# Mount an overlay on /sysroot/etc. Its upper layer is on /run, which carries
# across switch-root, and holds the persisted files restored from storage.

set -eu

list=/sysroot/usr/lib/rpi-image-gen/early-persist-files
src="/sysroot<PERSISTENT_DIR>/common/etc"
run=/run/rpi-etc-overlay

mkdir -p "${run}/upper" "${run}/work"

if [ -s "$list" ] && [ -d "$src" ]; then
   sed 's|^/etc/||' "$list" |
      rsync -a --numeric-ids --ignore-missing-args --files-from=- "${src}/" "${run}/upper/"
fi

mount -t overlay overlay \
   -o "lowerdir=/sysroot/etc,upperdir=${run}/upper,workdir=${run}/work" /sysroot/etc
