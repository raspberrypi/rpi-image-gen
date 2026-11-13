#!/bin/sh
# Mount an overlay on /sysroot/etc. Its upper layer is on /run, which carries
# across switch-root, and holds the persisted files restored from storage.

set -eu

manifest=/sysroot/usr/lib/rpi-image-gen/slot-state.manifest
src="/sysroot<PERSISTENT_DIR>/common/etc"
run=/run/rpi-etc-overlay

mkdir -p "${run}/upper" "${run}/work"

# The EarlyPersistFile= paths in the manifest, relative to /etc
files() {
   while read -r op path _; do
      case "$op" in
         EarlyPersistFile) echo "${path#/etc/}" ;;
      esac
   done < "$manifest"
}

if [ -f "$manifest" ] && [ -d "$src" ]; then
   files | rsync -a --numeric-ids --ignore-missing-args --files-from=- "${src}/" "${run}/upper/"
fi

mount -t overlay overlay \
   -o "lowerdir=/sysroot/etc,upperdir=${run}/upper,workdir=${run}/work" /sysroot/etc
