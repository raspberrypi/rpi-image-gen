#!/bin/bash

# IDP/PMAP schema validation test suite
# Usage: just run it

IGTOP=$(readlink -f "$(dirname "$0")/../../")

SCHEMA="${IGTOP}/layer/base/schemas/provisionmap/v1/schema.json"
PATH="${IGTOP}/bin:$PATH"

# Dummy values for template substitution.
# BOOT_UUID uses vfat format (XXXX-XXXX) to match build-time generation.
export BOOT_UUID="ABCD-1234"
export SYSTEM_UUID="00000000-0000-0000-0000-000000000002"
export CRYPT_UUID="00000000-0000-0000-0000-000000000003"

PMAP_TMP=$(mktemp)
trap 'rm -f "$PMAP_TMP"' EXIT

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

    output=$(envsubst '${BOOT_UUID} ${SYSTEM_UUID} ${CRYPT_UUID}' < "$pmap" > "$PMAP_TMP" &&
        pmap --schema "$SCHEMA" --file "$PMAP_TMP" 2>&1)
    exit_code=$?

    if [ "$exit_code" -eq 0 ]; then
        print_pass "$name should validate"
    else
        print_fail "$name should validate" "$output"
    fi

    echo ""
done < <(find "${IGTOP}/image" -name 'provisionmap-*.json' -print0 | sort -z)

print_summary
