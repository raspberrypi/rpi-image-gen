#!/bin/bash

# DEB822 trait registry test suite
# Usage: just run it

IGTOP=$(readlink -f "$(dirname "$0")/../../")
TRAIT="${IGTOP}/test/trait"

PATH="$IGTOP/bin:$PATH"

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

print_header "TRAIT REGISTRY TESTS"

# Essentially lint / validation checkers
run_test "invalid-trait-valid-type-parse" \
    "ig metadata --parse ${TRAIT}/invalid-trait-valid-type.deb822" \
    1 \
    "Trait with non-bool Valid: should fail to parse"

run_test "invalid-trait-valid-type-validate" \
    "ig metadata --validate ${TRAIT}/invalid-trait-valid-type.deb822" \
    1 \
    "Trait with non-bool Valid: should fail to validate"

run_test "invalid-trait-trigger-non-boolean-parse" \
    "ig metadata --parse ${TRAIT}/invalid-trait-trigger-non-boolean.deb822" \
    1 \
    "Trait Triggers: action with a non-boolean value should fail to parse"

run_test "invalid-trait-trigger-non-boolean-validate" \
    "ig metadata --validate ${TRAIT}/invalid-trait-trigger-non-boolean.deb822" \
    1 \
    "Trait Triggers: action with a non-boolean value should fail to validate"

run_test "invalid-trait-trigger-not-true-parse" \
    "ig metadata --parse ${TRAIT}/invalid-trait-trigger-not-true.deb822" \
    1 \
    "Trait Triggers: action setting a false-ish value should fail to parse"

run_test "invalid-trait-trigger-not-true-validate" \
    "ig metadata --validate ${TRAIT}/invalid-trait-trigger-not-true.deb822" \
    1 \
    "Trait Triggers: action setting a false-ish value should fail to validate"

run_test "invalid-trait-unsupported-field-parse" \
    "ig metadata --parse ${TRAIT}/invalid-trait-unsupported-field.deb822" \
    1 \
    "Trait with a typo'd/unsupported attribute field should fail to parse"

run_test "invalid-trait-unsupported-field-validate" \
    "ig metadata --validate ${TRAIT}/invalid-trait-unsupported-field.deb822" \
    1 \
    "Trait with a typo'd/unsupported attribute field should fail to validate"

# Multi-file tree loading errors - each fixture's trait/ combines with the
# built-in tree via -S, exactly as a real OEM srcroot would.
run_test "trait-forward-reference-is-error" \
    "ig config --trait -S ${TRAIT}/fixtures/forward-ref" \
    1 \
    "A Requires: forward reference to a not-yet-loaded token should be a hard error"

run_test "trait-namespace-node-reference-is-error" \
    "ig config --trait -S ${TRAIT}/fixtures/namespace-node-reference" \
    1 \
    "Requires: referencing a bare namespace node should be a hard error"

run_test "trait-duplicate-definition-across-srcroot-is-error" \
    "ig config --trait -S ${TRAIT}/fixtures/oem-duplicate" \
    1 \
    "Redefining an existing built-in token from an external srcroot should be a hard error"

run_test "trait-namespace-node-duplicate-within-same-root-is-error" \
    "ig config --trait -S ${TRAIT}/fixtures/namespace-same-root-duplicate" \
    1 \
    "Two top-level files in the same root both defining the same namespace node should be a hard error"

# Functional verification - resolve() semantics (conditional Triggers,
# Requires validate-only gating) that the --trait CLI never exercises,
# since it only ever calls expand()/by_prefix(), not resolve().
run_test "trait-registry-deb822-parsing" \
    "python3 ${TRAIT}/test_trait_registry.py" \
    0 \
    "DEB822 trait registry resolve() semantics not reachable via the CLI"

print_summary
