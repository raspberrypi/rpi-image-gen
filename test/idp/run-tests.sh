#!/bin/bash

# IDP/PMAP schema validation test suite
# Usage: just run it

IGTOP=$(readlink -f "$(dirname "$0")/../../")

SCHEMA="${IGTOP}/layer/rpi/schemas/provisionmap/v1/schema.json"
PATH="${IGTOP}/bin:$PATH"

# Dummy values for template substitution.
# BOOT_UUID uses vfat format (XXXX-XXXX) to match build-time generation.
export BOOT_UUID="ABCD-1234"
export SYSTEM_UUID="00000000-0000-0000-0000-000000000002"
export CRYPT_UUID="00000000-0000-0000-0000-000000000003"
export LUKS_CIPHER="aes-xts-plain64"
export LUKS_KEYSIZE="512"
export LUKS_HASH="sha256"
export LUKS_SECTOR_SIZE_ATTR=""

PMAP_TMP=$(mktemp)
HOOK_OUT=$(mktemp -d)
trap 'rm -rf "$PMAP_TMP" "$HOOK_OUT"' EXIT

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


print_header "PMAP VALIDATION"

while IFS= read -r -d '' pmap; do
    name="${pmap#${IGTOP}/image/}"
    ((TOTAL_TESTS++))
    print_test "$name"

    output=$(envsubst '${BOOT_UUID} ${SYSTEM_UUID} ${CRYPT_UUID} ${LUKS_CIPHER} ${LUKS_KEYSIZE} ${LUKS_HASH} ${LUKS_SECTOR_SIZE_ATTR} ' < "$pmap" > "$PMAP_TMP" &&
        pmap --schema "$SCHEMA" --file "$PMAP_TMP" 2>&1)
    exit_code=$?

    if [ "$exit_code" -eq 0 ]; then
        print_pass "$name should validate"
    else
        print_fail "$name should validate" "$output"
    fi

    echo ""
done < <(find "${IGTOP}/image" -name 'provisionmap-*.json' -print0 | sort -z)


print_header "LUKS2 SECTOR SIZE"

# Set luks2.sector_size on every encrypted container of a substituted PMAP
# and check the result against the schema.
check_sector_size() {
    local value=$1 expect=$2 output exit_code
    local pmap="${IGTOP}/image/gpt/ab_userdata/image.d/device/provisionmap-crypt.json"

    ((TOTAL_TESTS++))
    print_test "luks2.sector_size $value"

    output=$(envsubst '${BOOT_UUID} ${SYSTEM_UUID} ${CRYPT_UUID} ${LUKS_CIPHER} ${LUKS_KEYSIZE} ${LUKS_HASH} ${LUKS_SECTOR_SIZE_ATTR} ' < "$pmap" |
        python3 -I -c '
import json, sys
data = json.load(sys.stdin)
value = json.loads(sys.argv[1])
def walk(node):
    if isinstance(node, dict):
        if isinstance(node.get("luks2"), dict):
            node["luks2"]["sector_size"] = value
        for child in node.values():
            walk(child)
    elif isinstance(node, list):
        for child in node:
            walk(child)
walk(data)
json.dump(data, sys.stdout)
' "$value" > "$PMAP_TMP" &&
        pmap --schema "$SCHEMA" --file "$PMAP_TMP" 2>&1)
    exit_code=$?

    if [ "$expect" = valid ] && [ "$exit_code" -eq 0 ]; then
        print_pass "luks2.sector_size $value should validate"
    elif [ "$expect" = invalid ] && [ "$exit_code" -ne 0 ]; then
        print_pass "luks2.sector_size $value should be rejected"
    else
        print_fail "luks2.sector_size $value should be $expect" "$output"
    fi

    echo ""
}

for size in 512 1024 2048 4096; do
    check_sector_size "$size" valid
done
for size in 0 256 3000 8192 '"4096"'; do
    check_sector_size "$size" invalid
done

print_header "PMAP HOOKS"

# Run an image's PMAP install hook and check that it writes a valid PMAP
# carrying luks2.sector_size on every encrypted container only when
# IGconf_device_luks2_sector_size is set.
check_pmap_hook() {
    local hook=$1 pmapname=$2 sector_size=$3 output exit_code
    local name="${hook#${IGTOP}/image/} ${pmapname} sector_size='${sector_size}'"

    ((TOTAL_TESTS++))
    print_test "$name"

    rm -f "${HOOK_OUT}/provisionmap.json"
    output=$(cd "$(dirname "$hook")" &&
        env \
            IGconf_image_pmap="$pmapname" \
            IGconf_image_outputdir="$HOOK_OUT" \
            IGconf_image_name="test" \
            IGconf_image_version="1" \
            IGconf_device_luks2_cipher="$LUKS_CIPHER" \
            IGconf_device_luks2_keysize="$LUKS_KEYSIZE" \
            IGconf_device_luks2_hash="$LUKS_HASH" \
            IGconf_device_luks2_sector_size="$sector_size" \
            LAYER_UUID="00000000-0000-0000-0000-000000000004" \
        sh "$hook" 2>&1 &&
        pmap --schema "$SCHEMA" --file "${HOOK_OUT}/provisionmap.json" 2>&1 &&
        python3 -I -c '
import json, sys
want = int(sys.argv[2]) if sys.argv[2] else None
found = []
def walk(node):
    if isinstance(node, dict):
        if isinstance(node.get("luks2"), dict):
            found.append(node["luks2"].get("sector_size"))
        for child in node.values():
            walk(child)
    elif isinstance(node, list):
        for child in node:
            walk(child)
walk(json.load(open(sys.argv[1])))
if not found or any(v != want for v in found):
    sys.exit(f"luks2.sector_size is {found}, expected {want} on each container")
' "${HOOK_OUT}/provisionmap.json" "$sector_size" 2>&1)
    exit_code=$?

    if [ "$exit_code" -eq 0 ]; then
        print_pass "$name"
    else
        print_fail "$name" "$output"
    fi

    echo ""
}

for sector_size in "" 4096; do
    for pmapname in crypt cryptdata cryptslots; do
        check_pmap_hook "${IGTOP}/image/gpt/ab_userdata/image.d/hooks/customize05-pmap" "$pmapname" "$sector_size"
    done
    check_pmap_hook "${IGTOP}/image/mbr/simple_dual/image.d/hooks/customize10-pmap" crypt "$sector_size"
done

print_summary
