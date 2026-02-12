#!/bin/bash
set -uo pipefail

# rpi-image-gen metadata parsing test suite
# Usage: just run it

IGTOP=$(readlink -f "$(dirname "$0")/../../")
META="${IGTOP}/test/meta"
PIPELINE_DIR=$(mktemp -d -t meta-layers.XXXXXX)
trap 'rm -rf "$PIPELINE_DIR"' EXIT

PATH="$IGTOP/bin:$PATH"

# Copy fixtures to a clean work dir (skip duplicate-name fixture for positive cases)
for f in "$META"/*.yaml; do
    base=$(basename "$f")
    if [ "$base" = "layer-duplicate-name.yaml" ]; then
        continue
    fi
    if [[ "$base" == lint-* ]]; then
        continue
    fi
    cp "$f" "$PIPELINE_DIR/$base"
done

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

cleanup_env() {
    unset $(env | grep '^IGconf_' | cut -d= -f1)
    unset NONEXISTENT_VAR
}

setup_test_env() {
    export IGconf_basic_hostname="test-host"
    export IGconf_types_name="test-app"
    export IGconf_types_timeout="60"
    export IGconf_types_debug="true"
    export IGconf_types_environment="development"
    export IGconf_types_email="test@example.com"
    export IGconf_valfail_port="99999"
    export IGconf_valfail_email="not-an-email"
    export IGconf_valfail_required=""
}

make_pipeline_env() {
    local target_file="$1"
    shift
    {
        printf "IGROOT=/tmp/pipeline\n"
        printf "SRCROOT=/tmp/pipeline/src\n"
        for line in "$@"; do
            printf "%s\n" "$line"
        done
    } > "$target_file"
}

# ---------------------------------------------------------------------------
print_header "VALID METADATA TESTS"

run_test "valid-basic-parse" \
    "ig metadata --parse ${META}/valid-basic.yaml" \
    0 \
    "Valid basic metadata should parse successfully"

run_test "valid-basic-validate" \
    "ig metadata --validate ${META}/valid-basic.yaml" \
    0 \
    "Valid basic metadata should validate successfully"

run_test "valid-basic-describe" \
    "ig metadata --describe ${META}/valid-basic.yaml" \
    0 \
    "Valid basic metadata should describe successfully"

setup_test_env
run_test "valid-all-types-parse" \
    "ig metadata --parse ${META}/valid-all-types.yaml" \
    0 \
    "Valid all-types metadata should parse successfully"

run_test "valid-all-types-validate" \
    "ig metadata --validate ${META}/valid-all-types.yaml" \
    0 \
    "Valid all-types metadata should validate successfully"

run_test "valid-conflicts" \
    "ig metadata --validate ${META}/valid-conflicts.yaml" \
    0 \
    "Conflicting vars should pass when only one side is set"

run_test "valid-conflicts-conditional" \
    "ig metadata --validate ${META}/valid-conflicts-conditional.yaml" \
    0 \
    "Conditional conflicts should pass when condition does not match"

run_test "valid-conflicts-conditional-not-eq" \
    "ig metadata --validate ${META}/valid-conflicts-conditional-not-eq.yaml" \
    0 \
    "Not-equals conflicts should pass when values are equal"

run_test "valid-conflicts-when" \
    "ig metadata --validate ${META}/valid-conflicts-when.yaml" \
    0 \
    "when= conflicts should pass when condition does not match"

run_test "valid-conflicts-when-multiple" \
    "ig metadata --validate ${META}/valid-conflicts-when-multiple.yaml" \
    0 \
    "when= conflicts should coexist with other conflicts"

run_test "valid-conflicts-when-whitespace" \
    "ig metadata --validate ${META}/valid-conflicts-when-whitespace.yaml" \
    0 \
    "when= conflicts should tolerate extra whitespace"

run_test "valid-conflicts-when-igconf" \
    "ig metadata --validate ${META}/valid-conflicts-when-igconf.yaml" \
    0 \
    "when= conflicts should accept IGconf_ targets"

run_test "valid-conflicts-when-multiline" \
    "ig metadata --validate ${META}/valid-conflicts-when-multiline.yaml" \
    0 \
    "when= conflicts should support multi-line specs"

run_test "valid-all-types-set" \
    "ig metadata --parse ${META}/valid-all-types.yaml" \
    0 \
    "Valid all-types metadata should set variables successfully"

run_test "valid-requirements-only-parse" \
    "setup_test_env; ig metadata --parse ${META}/valid-requirements-only.yaml" \
    0 \
    "Valid requirements-only metadata should parse successfully"

run_test "valid-requirements-only-validate" \
    "setup_test_env; ig metadata --validate ${META}/valid-requirements-only.yaml" \
    0 \
    "Valid requirements-only metadata should validate successfully"

cleanup_env
run_test "set-policies-set" \
    "ig metadata --parse ${META}/set-policies.yaml" \
    0 \
    "Set policies should work correctly"

cleanup_env
run_test "triggers-parse" \
    "cleanup_env; ig metadata --parse ${META}/valid-triggers.yaml" \
    0 \
    "Triggers metadata should parse successfully"

run_test "triggers-set" \
    'cleanup_env; TMP_OUT=$(mktemp); ig metadata --parse ${META}/valid-triggers.yaml --write-out "$TMP_OUT" && grep "^IG_TRIG_FAST=\"1\"$" "$TMP_OUT" && grep "^IG_TRIG_FAST2=\"1\"$" "$TMP_OUT" && grep "^IG_TRIG_ANY=\"1\"$" "$TMP_OUT" && grep "^IG_TRIG_EXTRA=\"1\"$" "$TMP_OUT"; status=$?; rm -f "$TMP_OUT"; exit $status' \
    0 \
    "Trigger rules should set target variables (including inherited condition actions)"

# ---------------------------------------------------------------------------
print_header "INVALID METADATA TESTS"

cleanup_env
run_test "invalid-no-prefix-parse" \
    "ig metadata --parse ${META}/invalid-no-prefix.yaml" \
    1 \
    "Metadata with variables but no prefix should fail to parse"

run_test "invalid-no-prefix-validate" \
    "ig metadata --validate ${META}/invalid-no-prefix.yaml" \
    1 \
    "Metadata with variables but no prefix should fail to validate"

run_test "invalid-malformed-parse" \
    "ig metadata --parse ${META}/invalid-malformed.yaml" \
    1 \
    "Malformed metadata should fail to parse"

run_test "invalid-malformed-validate" \
    "ig metadata --validate ${META}/invalid-malformed.yaml" \
    1 \
    "Malformed metadata should fail to validate"

run_test "invalid-unsupported-parse" \
    "ig metadata --parse ${META}/invalid-unsupported-fields.yaml" \
    1 \
    "Metadata with unsupported fields should fail to parse"

run_test "invalid-unsupported-validate" \
    "ig metadata --validate ${META}/invalid-unsupported-fields.yaml" \
    1 \
    "Metadata with unsupported fields should fail to validate"

run_test "invalid-conflicts" \
    "ig metadata --validate ${META}/invalid-conflicts.yaml" \
    1 \
    "Conflicting vars both set should fail to validate"

run_test "invalid-conflicts-conditional" \
    "ig metadata --validate ${META}/invalid-conflicts-conditional.yaml" \
    1 \
    "Conditional conflicts should fail when condition matches"

run_test "invalid-conflicts-conditional-not-eq" \
    "ig metadata --validate ${META}/invalid-conflicts-conditional-not-eq.yaml" \
    1 \
    "Not-equals conflicts should fail when values differ"

run_test "invalid-conflicts-when" \
    "ig metadata --validate ${META}/invalid-conflicts-when.yaml" \
    1 \
    "when= conflicts should fail when condition matches"

run_test "invalid-conflicts-when-missing-value" \
    "ig metadata --parse ${META}/invalid-conflicts-when-missing-value.yaml" \
    1 \
    "when= conflicts should fail when value is missing"

run_test "invalid-conflicts-when-missing-conflict" \
    "ig metadata --parse ${META}/invalid-conflicts-when-missing-conflict.yaml" \
    1 \
    "when= conflicts should fail when conflict is missing"

run_test "invalid-conflicts-when-multiline-missing-conflict" \
    "ig metadata --parse ${META}/invalid-conflicts-when-multiline-missing-conflict.yaml" \
    1 \
    "when= conflicts should fail when split across lines"

run_test "invalid-conflicts-malformed" \
    "ig metadata --parse ${META}/invalid-conflicts-malformed.yaml" \
    1 \
    "Malformed conflict specifiers should fail to parse"

run_test "invalid-conflicts-operator" \
    "ig metadata --parse ${META}/invalid-conflicts-operator.yaml" \
    1 \
    "Unsupported conflict operators should fail to parse"

run_test "invalid-conflicts-skip" \
    "ig metadata --validate ${META}/invalid-conflicts-skip.yaml" \
    0 \
    "Conflicts ignored when a side has no resolved value"

run_test "invalid-trigger-action-parse" \
    "ig metadata --parse ${META}/invalid-trigger-verb.yaml" \
    1 \
    "Unknown trigger action should fail to parse"

cleanup_env
run_test "invalid-trigger-validation" \
    "cleanup_env; ig metadata --parse ${META}/invalid-trigger-validation.yaml" \
    1 \
    "Trigger-injected value that violates validation should fail to parse"

cleanup_env
run_test "invalid-trigger-validation-force" \
    "cleanup_env; ig metadata --parse ${META}/invalid-trigger-validation-force.yaml" \
    1 \
    "Trigger-injected invalid value should fail even when target has force policy"

cleanup_env
run_test "invalid-trigger-env-override" \
    "cleanup_env; IGconf_image_rootfs_type=btrfs ig metadata --parse ${META}/invalid-trigger-env-override.yaml" \
    1 \
    "Trigger should fire when source var is overridden via env/config"

run_test "invalid-yaml-syntax-layer-validate" \
    "ig metadata --validate ${META}/invalid-yaml-syntax.yaml" \
    1 \
    "Invalid YAML syntax should fail validation"

setup_test_env
run_test "validation-failures-parse" \
    "ig metadata --parse ${META}/validation-failures.yaml" \
    1 \
    "Metadata with validation failures should fail to parse"

run_test "validation-failures-validate" \
    "ig metadata --validate ${META}/validation-failures.yaml" \
    1 \
    "Metadata with validation failures should fail to validate"

# ---------------------------------------------------------------------------
print_header "LAYER FUNCTIONALITY TESTS"

run_test "layer-with-deps-info" \
    "ig layer --path ${PIPELINE_DIR} --describe test-with-deps" \
    0 \
    "Layer with dependencies should show info successfully"

setup_test_env
run_test "layer-with-deps-validate" \
    "ig metadata --validate ${PIPELINE_DIR}/valid-with-deps.yaml" \
    0 \
    "Layer with dependencies should validate successfully"

run_test "layer-missing-dep-validate" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-missing-dep --path "${PIPELINE_DIR}" --env-out "$TMP_OUT" >/dev/null; \
     status=$?; rm -f "$TMP_ENV" "$TMP_OUT"; exit $status' \
    1 \
    "Layer with missing dependencies should fail validation"

run_test "layer-missing-dep-check" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-missing-dep --path "${PIPELINE_DIR}" --env-out "$TMP_OUT" >/dev/null; \
     status=$?; rm -f "$TMP_ENV" "$TMP_OUT"; exit $status' \
    1 \
    "Layer dependency check should fail for missing dependencies"

run_test "layer-circular-deps-check" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-circular-a --path "${PIPELINE_DIR}" --env-out "$TMP_OUT" >/dev/null; \
     status=$?; rm -f "$TMP_ENV" "$TMP_OUT"; exit $status' \
    1 \
    "Circular dependency check should fail"

run_test "layer-build-order-circular" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-circular-a --path "${PIPELINE_DIR}" --env-out "$TMP_OUT" >/dev/null; \
     status=$?; rm -f "$TMP_ENV" "$TMP_OUT"; exit $status' \
    1 \
    "Build order should fail for circular dependencies"

run_test "layer-duplicate-name-handling" \
    "ig layer --path ${META} --list" \
    1 \
    "Duplicate layer name should raise an error"

# ---------------------------------------------------------------------------
print_header "OTHER TESTS"

run_test "meta-help-validation" \
    "ig metadata --help-validation" \
    0 \
    "Help validation should work"

run_test "meta-gen" \
    "ig metadata --gen" \
    0 \
    "Metadata generation should work"

run_test "layer-build-order-valid" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" "IGconf_basic_hostname=test-host" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-with-deps --path "${PIPELINE_DIR}" --env-out "$TMP_OUT" >/dev/null; \
     status=$?; rm -f "$TMP_ENV" "$TMP_OUT"; exit $status' \
    0 \
    "Build order should work for valid dependencies"

run_test "layer-discovery" \
    "ig layer --path ${PIPELINE_DIR} --describe test-basic" \
    0 \
    "Layer discovery should find test layers"

# ---------------------------------------------------------------------------
print_header "AUTO-SET AND APPLY-ENV TESTS"

NET_FILE="${PIPELINE_DIR}/network-x-env.yaml"

cleanup_env
unset IGconf_net_interface
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${NET_FILE}
run_test "meta-parse-auto-set" \
    "ig metadata --parse ${NET_FILE}" \
    0 \
    "Meta parse should auto-set variables with Set: y policy"
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${NET_FILE}

cleanup_env
run_test "layer-apply-env-valid" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-set-policies --path "${PIPELINE_DIR}" --env-out "$TMP_OUT" >/dev/null && \
     grep -q "IGconf_setpol_alwaysset=default-value" "$TMP_OUT" && \
     grep -q "IGconf_setpol_defaultbehavior=default-value" "$TMP_OUT" && \
     rm -f "$TMP_ENV" "$TMP_OUT"' \
    0 \
    "Pipeline apply-env should work with valid metadata"

run_test "layer-apply-env-validates-against-resolved-definition" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-resolved-validator-base test-resolved-validator-consumer --path "${PIPELINE_DIR}" --env-out "$TMP_OUT" >/dev/null && \
     grep -q "^IGconf_device_storage_type=emmc8G$" "$TMP_OUT" && \
     grep -q "^IGconf_image_size=8G$" "$TMP_OUT"; \
     status=$?; rm -f "$TMP_ENV" "$TMP_OUT"; exit $status' \
    0 \
    "Pipeline should validate storage_type using the resolved consumer definition"

run_test "layer-apply-env-conflict-with-env-overrides" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && TMP_DIR=$(mktemp -d) && \
     cat > "$TMP_DIR/base.yaml" << "EOF" && \
# METABEGIN
# X-Env-Layer-Name: test-conflict-base
# X-Env-Layer-Desc: Base layer for conflict regression
# X-Env-Layer-Version: 1.0.0
# X-Env-Layer-Category: test
# X-Env-VarPrefix: cflt
# X-Env-Var-variant: 8G
# X-Env-Var-variant-Valid: 8G,16G,32G,lite
# X-Env-Var-variant-Set: lazy
# X-Env-Var-storage_type: sd
# X-Env-Var-storage_type-Valid: sd,emmc
# X-Env-Var-storage_type-Set: lazy
# METAEND
EOF
     cat > "$TMP_DIR/consumer.yaml" << "EOF" && \
# METABEGIN
# X-Env-Layer-Name: test-conflict-consumer
# X-Env-Layer-Desc: Variant conflicts with emmc when lite
# X-Env-Layer-Version: 1.0.0
# X-Env-Layer-Category: test
# X-Env-Layer-Requires: test-conflict-base
# X-Env-VarPrefix: cflt
# X-Env-Var-variant: 8G
# X-Env-Var-variant-Valid: 8G,16G,32G,lite
# X-Env-Var-variant-Set: lazy
# X-Env-Var-variant-Conflicts: when=lite storage_type=emmc
# METAEND
EOF
     make_pipeline_env "$TMP_ENV" "IGconf_cflt_variant=lite" "IGconf_cflt_storage_type=emmc" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-conflict-consumer --path "$TMP_DIR" --env-out "$TMP_OUT" >/dev/null; \
     status=$?; rm -f "$TMP_ENV" "$TMP_OUT"; rm -rf "$TMP_DIR"; exit $status' \
    1 \
    "Pipeline should reject conflicts evaluated from current env values"

run_test "layer-apply-env-invalid" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-unsupported --path "${PIPELINE_DIR}" --env-out "$TMP_OUT" >/dev/null; \
     status=$?; rm -f "$TMP_ENV" "$TMP_OUT"; exit $status' \
    1 \
    "Pipeline apply-env should fail with invalid metadata"

cleanup_env
unset IGconf_net_interface
IGconf_net_interface_before=$(env | grep IGconf_net_interface || echo "UNSET")
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${NET_FILE}
run_test "meta-parse-sets-required-vars" \
    "test \"$IGconf_net_interface_before\" = \"UNSET\" && ig metadata --parse ${NET_FILE} | grep 'IGconf_net_interface=eth0'" \
    0 \
    "Meta parse should set required variables from defaults when Set: y"
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${NET_FILE}

cleanup_env
unset IGconf_net_interface IGconf_net_ip IGconf_net_dns
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${NET_FILE}
run_test "layer-apply-env-sets-vars" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers network-setup --path "${PIPELINE_DIR}" --env-out "$TMP_OUT" >/dev/null && \
     grep -q "^IGconf_net_interface=eth0$" "$TMP_OUT" && \
     grep -q "^IGconf_net_ip=192.168.1.100$" "$TMP_OUT" && \
     rm -f "$TMP_ENV" "$TMP_OUT"' \
    0 \
    "Pipeline should set network variables when unset"
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${NET_FILE}

cleanup_env
unset IGconf_net_interface IGconf_net_ip IGconf_net_dns
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${NET_FILE}
run_test "meta-parse-required-auto-set-regression" \
    "ig metadata --parse ${NET_FILE} | grep 'IGconf_net_interface=eth0'" \
    0 \
    "Meta parse should work with required variables that have Set: y (regression test)"
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${NET_FILE}

cleanup_env
unset IGconf_net_interface IGconf_net_ip IGconf_net_dns
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${NET_FILE}
run_test "layer-apply-env-fails-required-no-set" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers network-setup --path "${PIPELINE_DIR}" --env-out "$TMP_OUT" >/dev/null; \
     status=$?; rm -f "$TMP_ENV" "$TMP_OUT"; exit $status' \
    1 \
    "Layer apply-env should fail when required variables have Set: n and are not provided"

cleanup_env
unset IGconf_net_interface IGconf_net_ip IGconf_net_dns
run_test "layer-apply-env-succeeds-required-manually-set" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" "IGconf_net_interface=wlan0" && \
     ig pipeline --env-in "$TMP_ENV" --layers network-setup --path "${PIPELINE_DIR}" --env-out "$TMP_OUT" >/dev/null && \
     grep -q "^IGconf_net_interface=wlan0$" "$TMP_OUT"; \
     status=$?; rm -f "$TMP_ENV" "$TMP_OUT"; exit $status' \
    0 \
    "Layer apply-env should succeed when required variables have Set: n but are manually provided"

cleanup_env
unset IGconf_net_interface IGconf_net_ip IGconf_net_dns
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${NET_FILE}
run_test "meta-parse-fails-required-no-set" \
    "ig metadata --parse ${NET_FILE}" \
    1 \
    "Meta parse should fail when required variables have Set: n and are not provided in environment"

cleanup_env
unset IGconf_net_interface IGconf_net_ip IGconf_net_dns
run_test "meta-parse-succeeds-required-manually-set" \
    "IGconf_net_interface=wlan0 ig metadata --parse ${NET_FILE} | grep 'IGconf_net_interface=wlan0'" \
    0 \
    "Meta parse should succeed when required variables have Set: n but are manually provided"

print_header "LINT TESTS"

run_test "lint-missing-layer-name" \
    "ig metadata --lint ${META}/lint-missing-layer-name.yaml" \
    1 \
    "Lint should fail when layer fields exist but Name is missing"

run_test "lint-unsupported-layer-field" \
    "ig metadata --lint ${META}/lint-unsupported-layer-field.yaml" \
    1 \
    "Lint should fail on unsupported layer field"

run_test "lint-unsupported-var-field" \
    "ig metadata --lint ${META}/lint-unsupported-var-field.yaml" \
    1 \
    "Lint should fail on unsupported env var field"

run_test "lint-orphan-attr" \
    "ig metadata --lint ${META}/lint-orphan-attr.yaml" \
    1 \
    "Lint should fail on orphaned attribute without base var"

run_test "lint-invalid-var-rule" \
    "ig metadata --lint ${META}/lint-invalid-var-rule.yaml" \
    1 \
    "Lint should fail on invalid per-variable validation rule"

run_test "lint-invalid-rule-list" \
    "ig metadata --lint ${META}/lint-invalid-rule-list.yaml" \
    1 \
    "Lint should fail on invalid VarRequires-Valid rule list"

run_test "lint-no-metadata" \
    "ig metadata --lint ${META}/lint-no-metadata.yaml" \
    1 \
    "Lint should fail when no X-Env-* metadata fields exist"

cleanup_env
print_summary
