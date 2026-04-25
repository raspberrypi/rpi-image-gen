#!/bin/bash
# initramfs-tools cryptroot installer (manual)

set -eu

: "${1:?chroot path not set}"
: "${PARTPROBE_DEVICES?not set}"
: "${CRYPT_CONTAINERS_FILE:?not set}"


# initramfs generation: Install run-time assets
install -m 0755 initramfs-tools/hooks/rpi-cryptroot-install \
   "$1/etc/initramfs-tools/hooks/rpi-cryptroot-install"


. $CRYPT_CONTAINERS_FILE


# initramfs run-time: Create the unlock script
mkdir -p $1/etc/initramfs-tools/scripts/local-top
cat > "$1/etc/initramfs-tools/scripts/local-top/rpi-cryptroot" << 'EOF'
#!/bin/sh
PREREQ=""
prereqs() { echo "$PREREQ"; }
case $1 in prereqs) prereqs; exit 0;; esac
. /scripts/functions

msg() {
    [ -w /dev/kmsg ] && echo "$@" > /dev/kmsg
    echo "$@"
}
EOF


# Emit one block per container
for container in "${CONTAINERS[@]}" ; do
    eval "uuid=\$${container}_UUID"
    eval "name=\$${container}_MNAME"
    eval "etype=\$${container}_ETYPE"

    cat >> "$1/etc/initramfs-tools/scripts/local-top/rpi-cryptroot" <<EOF

HW_ID=\$(block-device-id "/dev/disk/by-uuid/$uuid")
KEY=\$(echo "\$HW_ID" | rpi-fw-crypto hmac --in /dev/stdin --key-id 1 --outform hex)

if [ -n "\$KEY" ] && echo "\$KEY" | cryptsetup luksOpen "/dev/disk/by-uuid/$uuid" "$name"; then
    msg "$name ($uuid) unlocked"
else
    msg "Error: Failed to unlock $name ($uuid)" >&2
    reboot -f 2>/dev/null || echo b > /proc/sysrq-trigger
fi
[ "$etype" = "partitioned" ] && kpartx -av -p p "/dev/mapper/$name"
EOF
done
chmod +x "$1/etc/initramfs-tools/scripts/local-top/rpi-cryptroot"
