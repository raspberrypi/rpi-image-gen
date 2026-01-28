#!/bin/bash

set -eu

fs=$1
genimg_in=$2

[[ -d "$fs" ]] || exit 0


# Load pre-defined UUIDs
. ${genimg_in}/img_uuids


# mkfs cmdline args
MKE2FS_ARGS=()
MKEROFS_ARGS=("-z" "zstd")
case "$IGconf_device_sector_size" in
   4096)
      MKE2FS_ARGS+=("-b" "-4096")
      ;;
esac

MKE2FS_SYSTEM=("-U" "$SYSTEM_UUID")
MKEROFS_SYSTEM=("-U" "$SYSTEM_UUID")
MKE2FS_DATA=()

MKE2FS_SYSTEM+=("${MKE2FS_ARGS[@]}")
MKEROFS_SYSTEM+=("${MKEROFS_ARGS[@]}")
MKE2FS_DATA+=("${MKE2FS_ARGS[@]}")

MKE2FS_ARGS_SYSTEM="${MKE2FS_SYSTEM[*]}"
MKEROFS_ARGS_SYSTEM="${MKEROFS_SYSTEM[*]}"
MKE2FS_ARGS_DATA="${MKE2FS_DATA[*]}"


# Set up the partition layout for tryboot support. Partition numbering
# relates directly to the layout in genimage.cfg.in

cat << EOF > "${genimg_in}/autoboot.txt"
[all]
tryboot_a_b=1
boot_partition=2
[tryboot]
boot_partition=3
EOF


# Write genimage template
cat genimage-${IGconf_image_rootfs_type}.cfg.in | sed \
   -e "s|<IMAGE_DIR>|$IGconf_image_outputdir|g" \
   -e "s|<IMAGE_NAME>|$IGconf_image_name|g" \
   -e "s|<IMAGE_SUFFIX>|$IGconf_image_suffix|g" \
   -e "s|<BOOT_SIZE>|$IGconf_image_boot_part_size|g" \
   -e "s|<SYSTEM_SIZE>|$IGconf_image_system_part_size|g" \
   -e "s|<PERSISTENT_SIZE>|$IGconf_image_data_part_size|g" \
   -e "s|<SECTOR_SIZE>|$IGconf_device_sector_size|g" \
   -e "s|<SLOTP>|'$(readlink -ef slot-post-process-${IGconf_image_rootfs_type}.sh)'|g" \
   -e "s|<BOOT_LABEL>|$BOOT_LABEL|g" \
   -e "s|<SYSTEM_UUID>|$SYSTEM_UUID|g" \
   -e "s|<MKE2FS_CONF>|'$(readlink -ef mke2fs.conf)'|g" \
   -e "s|<MKE2FS_SYSTEM>|$MKE2FS_ARGS_SYSTEM|g" \
   -e "s|<MKEROFS_SYSTEM>|$MKEROFS_ARGS_SYSTEM|g" \
   -e "s|<MKE2FS_DATA>|$MKE2FS_ARGS_DATA|g" \
   > ${genimg_in}/genimage.cfg


# Create persistent skeleton - must match part names in genimage.cfg.in
mkdir -p ${fs}/persistent/slots/system_a/var
mkdir -p ${fs}/persistent/slots/system_b/var
mkdir -p ${fs}/persistent/common/etc

install -d -m 1777 ${fs}/persistent/slots/system_a/var/tmp
install -d -m 1777 ${fs}/persistent/slots/system_b/var/tmp


# machine-id(5)
wants_dir="${fs}/etc/systemd/system/sysinit.target.wants"
units=(
  "machine-id-sync.service"
)
install -d -m 0755 "${wants_dir}"
for unit in "${units[@]}"; do
  [ -f "${fs}/etc/systemd/system/${unit}" ] || die "missing ${unit}"
  chmod 0644 "${fs}/etc/systemd/system/${unit}"
  ln -sf "../${unit}" "${wants_dir}/${unit}"
done

# Ship an empty file, add entry for legacy dbus
rm -f "${fs}/etc/machine-id"
rm -f "${fs}/var/lib/dbus/machine-id"
install -m0644 -o root -g root /dev/null "${fs}/etc/machine-id"
ln -s /etc/machine-id "${fs}/var/lib/dbus/machine-id"


# /var is per-slot, so synchronise
rsync -aHAXS --numeric-ids --delete "${fs}/var/" "${fs}/persistent/slots/system_a/var/"
rsync -aHAXS --numeric-ids --delete "${fs}/var/" "${fs}/persistent/slots/system_b/var/"


# Journal is retained across slot rotations
install -d -m 2755 -o root -g systemd-journal "${fs}/persistent/log/journal"
# set preferences
# https://www.freedesktop.org/software/systemd/man/latest/journald.conf.html
install -d -m 0755 ${fs}/etc/systemd/journald.conf.d
cat > ${fs}/etc/systemd/journald.conf.d/persistent.conf <<'EOF'
[Journal]
Storage=persistent

# Reduce space
Compress=yes

# Lower disk budget
SystemMaxUse=512M
SystemMaxFileSize=20M

# No time window retention
MaxRetentionSec=0
MaxFileSec=0

# Endurance profile
RuntimeMaxUse=128M
SyncIntervalSec=2m
RateLimitInterval=30s
RateLimitBurst=2000

# Integrity
Seal=yes
EOF


# /home is bind mounted to /persistent/home and retained across slot rotations
# Mirror it
mkdir -p "${fs}/persistent/home/"
rsync -aHAXS --numeric-ids --delete "${fs}/home/" "${fs}/persistent/home/"

# Reclaim /home
find "${fs}/home" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +

# Reclaim /var but ensure skeleton exists for services that need PrivateTmp
# otherwise namespace setup will fail on the immutable root.
find "${fs}/var" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
install -d -m 1777 ${fs}/var/tmp
install -d -m 0755 ${fs}/var/log
install -d -m 0755 ${fs}/var/cache
install -d -m 0755 ${fs}/var/spool


# Older systemd (eg 252/Bookworm) sets up per‑service mount namespaces by
# bind mounting a read‑only snapshot of / under /run/systemd/unit-root then
# mounting APIVFS and PrivateTmp bits (eg, /dev, /proc, /sys) inside that.
# systemd is not able to create these on an immutable root if they don't
# exist. Even if we create them, namespace init fails (status=226/NAMESPACE).
# New systemd (eg 257/Trixie) does not have this problem. Only workaround is
# to relax the sandboxing for these services. See:
# https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html
ver=$(systemd-major "$fs")
[[ "$ver" =~ ^[0-9]+$ ]] || { echo "systemd-major error for $fs" >&2; exit 1; }
if [[ "$ver" -lt 257 ]]; then
  for svc in systemd-resolved systemd-timesyncd; do
    d="${fs}/etc/systemd/system/${svc}.service.d"
    mkdir -p "$d"
    cat > "${d}/immutable-root.conf" <<'EOF'
[Service]
PrivateDevices=no
EOF
  done
fi


# Perms for bind mounts on the immutable root
chmod 755 "${fs}/home"
chmod 755 "${fs}/var"

# Generate the persistent skeleton suitable for on-device overlay
tar --xattrs --xattrs-include='*' --acls --numeric-owner \
   -C "${fs}/persistent" \
   -czf "${genimg_in}/persistent-skel.tar.gz" \
   --exclude='lost+found' .
