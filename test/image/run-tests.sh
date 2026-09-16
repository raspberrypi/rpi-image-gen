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

SRC="${IGTOP}/test/image"
TEMPLATE="${IGTOP}/templates/rpi/boot-firmware/cmdline.txt"
BASE='console=serial0,115200 console=tty1 root=/dev/disk/by-slot/system fsck.repair=yes rootwait'
CR=$'\r'

# Stage $1 as cmdline.txt, run the BOOT arm of setup.sh and check the result
# is exactly one CR-free, LF-terminated line equal to $2. $3 is the value of
# cmdline_extra; when omitted the variable is left unset.
check_cmdline() {
    local d
    d=$(mktemp -d -p "$WORKDIR")
    cp "$1" "$d/cmdline.txt"
    local -a e=(IMAGEMOUNTPATH="$d")
    [ $# -ge 3 ] && e+=(IGconf_image_cmdline_extra="$3")
    env "${e[@]}" "$LAYER/setup.sh" BOOT || return 1
    test "$(wc -l < "$d/cmdline.txt")" -eq 1 &&
    ! grep -q "$CR" "$d/cmdline.txt" &&
    grep -qxF "$2" "$d/cmdline.txt"
}

print_header "KERNEL COMMAND LINE TESTS"

run_test "cmdline-unset" \
    'check_cmdline "$TEMPLATE" "$BASE"' \
    0 \
    "An unset variable should leave the command line unchanged"

run_test "cmdline-empty" \
    'check_cmdline "$TEMPLATE" "$BASE" ""' \
    0 \
    "An empty value should leave the command line unchanged"

run_test "cmdline-multiple" \
    'check_cmdline "$TEMPLATE" "$BASE quiet splash cgroup_enable=memory" "quiet splash cgroup_enable=memory"' \
    0 \
    "Several parameters should be appended"

EXTRA='foo=a|b bar=$x baz=100%s qux=a&b quux=a\nb glob=*'
run_test "cmdline-metachars" \
    'check_cmdline "$TEMPLATE" "$BASE $EXTRA" "$EXTRA"' \
    0 \
    "Metacharacters and backslashes reaching setup.sh should be written literally"

print_header "COMMAND LINE NORMALISATION TESTS"

run_test "cmdline-second-line" \
    'check_cmdline "$SRC/cmdline-second-line.txt" "console=tty1 root=/dev/disk/by-slot/system quiet" quiet' \
    0 \
    "A pre-existing second line should not survive"

run_test "cmdline-second-line-empty" \
    'check_cmdline "$SRC/cmdline-second-line.txt" "console=tty1 root=/dev/disk/by-slot/system" ""' \
    0 \
    "Normalisation should not depend on cmdline_extra being set"

run_test "cmdline-crlf" \
    'check_cmdline "$SRC/cmdline-crlf.txt" "console=tty1 root=/dev/disk/by-slot/system rootwait quiet" quiet' \
    0 \
    "A carriage return should be stripped before appending"

print_summary
