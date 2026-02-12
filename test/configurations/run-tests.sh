#!/bin/bash
set -uo pipefail

# rpi-image-gen config parsing test suite
# Usage: just run it

IGTOP=$(readlink -f "$(dirname "$0")/../../")
SRC="${IGTOP}/test/configurations"
IG=${IGTOP}/rpi-image-gen

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

print_header "DRY RUN CONFIG TESTS"

run_test "dryconfig1 - docker" \
    "printf 'n\n' | $IG build -S ${SRC} -c trixie-rpios-min-docker.yaml -I" \
    0 \
    "Configuration should parse successfully"

run_test "dryconfig2 - splash" \
    "printf 'n\n' | $IG build -S ${SRC} -c trixie-ab-min-splash.yaml -I" \
    0 \
    "Configuration should parse successfully"

run_test "dryconfig3 - examples/slim" \
    "printf 'n\n' | $IG build -S ${IGTOP}/examples/slim -c pi5-slim.yaml -I" \
    0 \
    "Configuration should parse successfully"

run_test "dryconfig4 - examples/webkiosk" \
    "printf 'n\n' | $IG build -S ${IGTOP}/examples/webkiosk -c kiosk.yaml -I" \
    0 \
    "Configuration should parse successfully"

run_test "dryconfig5 - examples/ota" \
    "printf 'n\n' | $IG build -S ${IGTOP}/examples/ota -c ota.yaml -I -- IGconf_connect_authkey=rpuak_foobar" \
    0 \
    "Configuration should parse successfully"

run_test "dryconfig5 - cm4" \
    "printf 'n\n' | $IG build -c trixie-minbase.yaml -I -- IGconf_device_layer=rpi-cm4" \
    0 \
    "Configuration should parse successfully"

run_test "dryconfig5 - cm4 lite w/emmc" \
    "printf 'n\n' | $IG build -c trixie-minbase.yaml -I -- IGconf_device_layer=rpi-cm4 IGconf_device_variant=lite IGconf_device_storage_type=emmc" \
    1 \
    "Configuration should reject cm4 lite w/emmc"

run_test "dryconfig6 - cm5" \
    "printf 'n\n' | $IG build -c trixie-minbase.yaml -I -- IGconf_device_layer=rpi-cm5" \
    0 \
    "Configuration should parse successfully"

run_test "dryconfig7 - cm5 lite w/emmc" \
    "printf 'n\n' | $IG build -c trixie-minbase.yaml -I -- IGconf_device_layer=rpi-cm5 IGconf_device_variant=lite IGconf_device_storage_type=emmc" \
    1 \
    "Configuration should reject cm5 lite w/emmc"

run_test "dryconfig8 - pi5" \
    "printf 'n\n' | $IG build -c trixie-minbase.yaml -I -- IGconf_device_layer=rpi5" \
    0 \
    "Configuration should parse correctly"

run_test "dryconfig9 - pi5 w/emmc" \
    "printf 'n\n' | $IG build -c trixie-minbase.yaml -I -- IGconf_device_layer=rpi5 IGconf_device_storage_type=emmc" \
    1 \
    "Configuration should reject pi5 w/emmc"

run_test "dryconfig10 - zero2w" \
    "printf 'n\n' | $IG build -c trixie-minbase.yaml -I -- IGconf_device_layer=rpizero2w" \
    0 \
    "Configuration should parse correctly"

print_summary
exit 0

