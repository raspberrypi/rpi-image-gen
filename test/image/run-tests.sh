#!/bin/bash
set -uo pipefail

# rpi-image-gen image layer test suite
# Usage: just run it

IGTOP=$(readlink -f "$(dirname "$0")/../../")
LAYER="${IGTOP}/image/mbr/simple_dual"

WORKDIR=$(mktemp -d -t image-layer.XXXXXX)
trap 'rm -rf "$WORKDIR"' EXIT

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

declare -a FAILED_TEST_NAMES=()

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_test() {
    echo -e "${YELLOW}Testing: $1${NC}"
}

print_pass() {
    echo -e "${GREEN}✓ PASS: $1${NC}"
    ((PASSED_TESTS++))
}

print_fail() {
    echo -e "${RED}✗ FAIL: $1${NC}"
    echo -e "${RED}  Error: $2${NC}"
    ((FAILED_TESTS++))
    FAILED_TEST_NAMES+=("$1")
}

run_test() {
    local test_name="$1"
    local command="$2"
    local expected_exit_code="$3"
    local description="$4"

    ((TOTAL_TESTS++))
    print_test "$test_name"

    local output
    output=$(eval "$command" 2>&1)
    local actual_exit_code=$?

    if [ "$actual_exit_code" -eq "$expected_exit_code" ]; then
        print_pass "$description"
    else
        print_fail "$description" "Expected exit code $expected_exit_code, got $actual_exit_code. Output: $output"
    fi

    echo ""
}

print_summary() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}TEST SUMMARY${NC}"
    echo -e "${BLUE}================================${NC}"
    echo -e "Total tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"

    if [ ${#FAILED_TEST_NAMES[@]} -gt 0 ]; then
        echo -e "\n${RED}Failed tests:${NC}"
        for test in "${FAILED_TEST_NAMES[@]}"; do
            echo -e "${RED}  - $test${NC}"
        done
    fi

    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed. Please check the output above.${NC}"
        exit 1
    fi
}

# Fixed environment for the layer scripts. Each test sets only the scheme,
# disk signature, rootfs type and directories it varies.
export LAYER_DIR="$LAYER"
export IGconf_image_name=t IGconf_image_suffix=img
export IGconf_image_boot_part_size=128M IGconf_image_root_part_size=1G
export IGconf_device_sector_size=512
export IGconf_fs_ext4_mkfs_args= IGconf_fs_btrfs_mkfs_args= IGconf_fs_vfat_mkfs_args=

# Stage a filesystem and output dir for setup.sh. $1 is the disk signature
# recorded in img_uuids, as preimage.sh would have left it. Echoes the
# directory.
stage_setup() {
    local d
    d=$(mktemp -d -p "$WORKDIR")
    mkdir -p "$d/etc"
    printf 'DISKSIG=%s\nBOOT_LABEL=ABCD1234\nBOOT_UUID=ABCD-1234\nROOT_UUID=x\nCRYPT_UUID=y\n' \
        "$1" > "$d/img_uuids"
    echo "$d"
}

# Run setup.sh against a staged dir. $1 dir, $2 scheme, $3 rootfs type,
# $4 label. The configured disk signature is always 'random':
# setup.sh must take the recorded value, never the configured one.
run_setup() {
    IMAGEMOUNTPATH="$1" IGconf_image_outputdir="$1" \
    IGconf_image_devid_scheme="$2" IGconf_image_disksig=random \
    IGconf_image_rootfs_type="$3" \
        "$LAYER/setup.sh" "$4"
}

# Run preimage.sh. $1 outputdir, $2 genimage dir, $3 scheme, $4 disk signature.
# The layer workdir is $1/work.
run_preimage() {
    IGconf_image_outputdir="$1" LAYER_WORKDIR="$1/work" IGconf_image_rootfs_type=ext4 \
    IGconf_image_devid_scheme="$3" IGconf_image_disksig="$4" \
        "$LAYER/image.d/hooks/preimage.sh" /nonexistent "$2"
}

# Stage an output dir and render genimage.cfg through preimage.sh.
# $1 scheme, $2 disk signature. Echoes "<outputdir> <genimage dir>".
stage_preimage() {
    local d g
    d=$(mktemp -d -p "$WORKDIR")
    g=$(mktemp -d -p "$WORKDIR")
    printf 'BOOT_LABEL=ABCD1234\nBOOT_UUID=ABCD-1234\nROOT_UUID=u\nCRYPT_UUID=c\n' > "$d/img_uuids"
    run_preimage "$d" "$g" "$1" "$2" >/dev/null 2>&1 \
        || echo "preimage.sh failed" > "$g/genimage.cfg"
    echo "$d $g"
}

print_header "DEVID SCHEME TESTS"

d=$(stage_setup 0xaabbccdd)
run_test "devid-by-slot" \
    'run_setup "$d" by-slot ext4 ROOT && \
     grep -qx "/dev/disk/by-slot/system  /  ext4 rw,relatime,errors=remount-ro,commit=30 0 1" "$d/etc/fstab" && \
     grep -q "^/dev/disk/by-slot/boot  /boot/firmware  vfat" "$d/etc/fstab"' \
    0 \
    "By-slot should keep the slot symlinks"

d=$(stage_setup 0xaabbccdd)
run_test "devid-partuuid" \
    'run_setup "$d" partuuid ext4 ROOT && \
     grep -q "^PARTUUID=aabbccdd-02  /  ext4 " "$d/etc/fstab" && \
     grep -q "^PARTUUID=aabbccdd-01  /boot/firmware  vfat" "$d/etc/fstab"' \
    0 \
    "Partuuid should reference boot as partition 1 and root as partition 2"

d=$(stage_setup 0xAABBCCDD)
run_test "devid-partuuid-case" \
    'run_setup "$d" partuuid ext4 ROOT && \
     grep -q "PARTUUID=aabbccdd-02" "$d/etc/fstab"' \
    0 \
    "An upper case disk signature should be lower cased"

d=$(stage_setup 0x12345678)
run_test "devid-partuuid-btrfs" \
    'run_setup "$d" partuuid btrfs ROOT && \
     grep -qx "PARTUUID=12345678-02  /  btrfs defaults 0 0" "$d/etc/fstab"' \
    0 \
    "Btrfs roots should use the same scheme"

print_header "KERNEL COMMAND LINE TESTS"

FRAG=work/for/linux-base/cmdline.d/50-root

read -r d g <<<"$(stage_preimage partuuid 0xAABBCCDD)"
run_test "devid-cmdline-partuuid" \
    'test "$(cat "$d/$FRAG")" = "-root=* root=PARTUUID=aabbccdd-02"' \
    0 \
    "Partuuid should replace root= with the lower cased partition 2 PARTUUID"

read -r d g <<<"$(stage_preimage by-slot random)"
run_test "devid-cmdline-by-slot" \
    'test "$(cat "$d/$FRAG")" = "-root=* root=/dev/disk/by-slot/system"' \
    0 \
    "By-slot should replace root= with the system slot link"

print_header "UNRESOLVED DISK SIGNATURE TESTS"

# A recorded value that is not a signature must not be used
d=$(stage_setup random)
run_test "devid-signature-unresolved" \
    'run_setup "$d" partuuid ext4 ROOT > "$WORKDIR/err" 2>&1; \
     test $? -ne 0 && grep -q "unresolved disk signature" "$WORKDIR/err"' \
    0 \
    "An unresolved signature should abort with a clear message"

# img_uuids can predate preimage.sh recording a signature
d=$(mktemp -d -p "$WORKDIR"); mkdir -p "$d/etc"; echo 'BOOT_LABEL=ABCD1234' > "$d/img_uuids"
run_test "devid-signature-absent" \
    'run_setup "$d" partuuid ext4 ROOT > "$WORKDIR/err" 2>&1; \
     test $? -ne 0 && grep -q "unresolved disk signature" "$WORKDIR/err"' \
    0 \
    "An absent signature should abort with a clear message"

print_header "DISK SIGNATURE RESOLUTION TESTS"

# The signature genimage stamps must be the one setup.sh derives PARTUUIDs from
read -r d g <<<"$(stage_preimage partuuid random)"
run_test "devid-signature-to-genimage" \
    'sig=$(sed -n "s/^DISKSIG=//p" "$d/img_uuids") && \
     echo "$sig" | grep -qE "^0x[0-9a-f]{8}$" && \
     grep -q "disk-signature = \"$sig\"" "$g/genimage.cfg"' \
    0 \
    "A generated signature should be the one written to genimage.cfg"

# 'random' is never left for genimage to resolve, whatever the scheme
read -r d g <<<"$(stage_preimage by-slot random)"
run_test "devid-signature-by-slot" \
    'sig=$(sed -n "s/^DISKSIG=//p" "$d/img_uuids") && \
     echo "$sig" | grep -qE "^0x[0-9a-f]{8}$" && \
     grep -q "disk-signature = \"$sig\"" "$g/genimage.cfg"' \
    0 \
    "By-slot should also resolve and record the signature"

read -r d g <<<"$(stage_preimage partuuid 0xDEADBEEF)"
run_test "devid-signature-explicit" \
    'grep -q "disk-signature = \"0xDEADBEEF\"" "$g/genimage.cfg" && \
     grep -qx "DISKSIG=0xDEADBEEF" "$d/img_uuids"' \
    0 \
    "A configured signature should reach genimage unchanged and be recorded"

# The value genimage stamps and the value fstab references must agree
read -r d g <<<"$(stage_preimage partuuid random)"
mkdir -p "$d/etc"
run_test "devid-signature-matches-fstab" \
    'run_setup "$d" partuuid ext4 ROOT && \
     sig=$(sed -n "s/^DISKSIG=0x//p" "$d/img_uuids" | tr "A-F" "a-f") && \
     grep -q "^PARTUUID=$sig-02  /  ext4 " "$d/etc/fstab" && \
     grep -q "root=PARTUUID=$sig-02$" "$d/$FRAG" && \
     grep -q "disk-signature = \"0x$sig\"" "$g/genimage.cfg"' \
    0 \
    "The generated signature should appear in genimage.cfg, fstab and the cmdline"

# Each run records exactly one signature, replacing the previous one
read -r d g <<<"$(stage_preimage partuuid random)"
run_test "devid-signature-replaced" \
    'run_preimage "$d" "$g" partuuid 0x11223344 && \
     grep -q "disk-signature = \"0x11223344\"" "$g/genimage.cfg" && \
     test "$(grep -c "^DISKSIG=" "$d/img_uuids")" -eq 1 && \
     grep -qx "DISKSIG=0x11223344" "$d/img_uuids" && \
     grep -qx "BOOT_UUID=ABCD-1234" "$d/img_uuids"' \
    0 \
    "A rerun should replace the recorded signature and keep the other identifiers"

print_summary
