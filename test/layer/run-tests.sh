#!/bin/bash

# rpi-image-gen metadata parsing test suite
# Usage: just run it

IGTOP=$(readlink -f "$(dirname "$0")/../../")
LAYERS="${IGTOP}/test/layer"

PATH="$IGTOP/bin:$PATH"
PATH="$LAYERS/tools:$PATH"
DYN_LAYER_DIR=$(mktemp -d -t dynamic-layers.XXXXXX)
PIPELINE_LAYER_DIR=$(mktemp -d -t pipeline-layers.XXXXXX)
trap 'rm -rf "$DYN_LAYER_DIR" "$PIPELINE_LAYER_DIR"' EXIT

PIPELINE_LAYER_FILES=(
  "valid-basic.yaml"
  "valid-all-types.yaml"
  "valid-with-deps.yaml"
  "set-policies.yaml"
  "invalid-unsupported-fields.yaml"
  "network-x-env.yaml"
  "lazy-first.yaml"
  "lazy-second.yaml"
  "force-overwrite.yaml"
  "test-dependency-top.yaml"
  "test-dependency-middle.yaml"
  "test-dependency-bottom.yaml"
  "arm64-toolchain.yaml"
  "debian-packages.yaml"
  "test-env-var-deps.yaml"
)

for file in "${PIPELINE_LAYER_FILES[@]}"; do
    cp "${LAYERS}/${file}" "$PIPELINE_LAYER_DIR/"
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Result tracking
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

    # Automatically inject dynamic layer search path when needed
    local patched_command="$command"
    local layer_spec="--path DYNlayer=$DYN_LAYER_DIR:$LAYERS"
    patched_command=${patched_command//--path "$LAYERS"/$layer_spec}
    patched_command=${patched_command//--path $LAYERS/$layer_spec}

    # Run the command and capture both stdout and stderr
    local output
    output=$(eval "$patched_command" 2>&1)
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


# Valid basic metadata
print_header "VALID METADATA TESTS"

run_test "valid-basic-parse" \
    "ig metadata --parse ${LAYERS}/valid-basic.yaml" \
    0 \
    "Valid basic metadata should parse successfully"

run_test "valid-basic-validate" \
    "ig metadata --validate ${LAYERS}/valid-basic.yaml" \
    0 \
    "Valid basic metadata should parse successfully"

run_test "valid-string-or-empty" \
    "ig metadata --validate ${LAYERS}/string-or-empty.yaml" \
    0 \
    "Empty string is valid when using string-or-empty validation rule"

run_test "valid-basic-describe" \
    "ig metadata --describe ${LAYERS}/valid-basic.yaml" \
    0 \
    "Valid basic metadata should describe successfully"

run_test "valid-dynamic-layer" \
    "ig metadata --validate ${LAYERS}/dynamic-valid.yaml" \
    0 \
    "Dynamic layer with generator should validate successfully"

# Valid all-types metadata
setup_test_env
run_test "valid-all-types-parse" \
    "ig metadata --parse ${LAYERS}/valid-all-types.yaml" \
    0 \
    "Valid all-types metadata should parse successfully"

run_test "valid-all-types-validate" \
    "ig metadata --validate ${LAYERS}/valid-all-types.yaml" \
    0 \
    "Valid all-types metadata should validate successfully"

run_test "valid-all-types-parse" \
    "ig metadata --parse ${LAYERS}/valid-all-types.yaml" \
    0 \
    "Valid all-types metadata should parse and set variables successfully"


# Valid requirements-only metadata
run_test "valid-requirements-only-parse" \
    "ig metadata --parse ${LAYERS}/valid-requirements-only.yaml" \
    0 \
    "Valid requirements-only metadata should parse successfully (no output expected)"

run_test "valid-requirements-only-validate" \
    "ig metadata --validate ${LAYERS}/valid-requirements-only.yaml" \
    0 \
    "Valid requirements-only metadata should validate successfully"


# Set policies
cleanup_env
run_test "set-policies-parse" \
    "ig metadata --parse ${LAYERS}/set-policies.yaml" \
    0 \
    "Set policies should work correctly"


print_header "INVALID METADATA TESTS"


# Invalid - no prefix
cleanup_env
run_test "invalid-no-prefix-parse" \
    "ig metadata --parse ${LAYERS}/invalid-no-prefix.yaml" \
    1 \
    "Metadata with variables but no prefix should fail to parse"

run_test "invalid-no-prefix-validate" \
    "ig metadata --validate ${LAYERS}/invalid-no-prefix.yaml" \
    1 \
    "Metadata with variables but no prefix should fail to validate"

run_test "invalid-dynamic-missing-generator" \
    "ig metadata --validate ${LAYERS}/invalid-dynamic-missing-generator.yaml" \
    1 \
    "Dynamic layer without a generator should fail to validate"

# Invalid - malformed syntax
run_test "invalid-malformed-parse" \
    "ig metadata --parse ${LAYERS}/invalid-malformed.yaml" \
    1 \
    "Malformed metadata should fail to parse"

run_test "invalid-malformed-validate" \
    "ig metadata --validate ${LAYERS}/invalid-malformed.yaml" \
    1 \
    "Malformed metadata should fail to validate"


# Invalid - unsupported fields
run_test "invalid-unsupported-parse" \
    "ig metadata --parse ${LAYERS}/invalid-unsupported-fields.yaml" \
    1 \
    "Metadata with unsupported fields should fail to parse"

run_test "invalid-unsupported-validate" \
    "ig metadata --validate ${LAYERS}/invalid-unsupported-fields.yaml" \
    1 \
    "Metadata with unsupported fields should fail to validate"


# Invalid - YAML syntax
run_test "invalid-yaml-syntax-layer-validate" \
    "ig metadata --validate ${LAYERS}/invalid-yaml-syntax.yaml" \
    1 \
    "Invalid YAML syntax should fail layer validation"


# Invalid - bad validation type
run_test "invalid-validation-type" \
    "ig metadata --validate ${LAYERS}/invalid-validation-type.yaml" \
    1 \
    "Invalid variable validation type should fail validation"


# Validation failures
cleanup_env
setup_test_env
run_test "validation-failures-parse" \
    "ig metadata --parse ${LAYERS}/validation-failures.yaml" \
    1 \
    "Metadata with validation failures should fail to parse"

run_test "validation-failures-validate" \
    "ig metadata --validate ${LAYERS}/validation-failures.yaml" \
    1 \
    "Metadata with validation failures should fail to validate"


print_header "LAYER FUNCTIONALITY TESTS"


# Layer with dependencies
setup_test_env

run_test "meta-validate-rejects-invalid-dependency-declaration" \
    "ig metadata --validate ${LAYERS}/invalid-layer-dep-fmt.yaml" \
    1 \
    "Meta validate should reject invalid declaration of dependencies"

run_test "meta-parse-rejects-invalid-dependency-declaration" \
    "ig metadata --parse ${LAYERS}/invalid-layer-dep-fmt.yaml" \
    1 \
    "Meta parse should perform validation of dependency declaration"

run_test "layer-with-deps-info" \
    "ig layer --path ${LAYERS} --describe test-with-deps" \
    0 \
    "Layer with dependencies should show info successfully"

# Layer with missing dependencies

# Duplicate layer name detection uses a temp dir to avoid side effects
tmp_dup_dir=$(mktemp -d)
cp "${LAYERS}/valid-basic.yaml" "$tmp_dup_dir/layer1.yaml"
cp "${LAYERS}/valid-basic.yaml" "$tmp_dup_dir/layer2.yaml"

run_test "layer-duplicate-name-detection" \
    "ig layer --path $tmp_dup_dir --list >/dev/null 2>&1" \
    1 \
    "Duplicate layer names should cause discovery to fail"

# Clean up temporary directory
rm -rf "$tmp_dup_dir"


print_header "OTHER TESTS"


# Help commands
run_test "meta-help-validation" \
    "ig metadata --help-validation" \
    0 \
    "Help validation should work"

run_test "meta-gen" \
    "ig metadata --gen" \
    0 \
    "Metadata generation should work"


# Layer management discovery
run_test "layer-discovery" \
    "ig layer --path ${LAYERS} --describe test-basic" \
    0 \
    "Layer discovery should find test layers"


print_header "AUTO-SET AND APPLY-ENV TESTS"


# Metadata parse with auto-set from policy
cleanup_env
unset IGconf_net_interface
# Temporarily change Set policy to y for this test
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${LAYERS}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml
run_test "meta-parse-auto-set" \
    "ig metadata --parse ${LAYERS}/network-x-env.yaml" \
    0 \
    "Meta parse should auto-set variables with Set: y policy"
# Restore original setting
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${LAYERS}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml


# Layer apply-env with valid metadata
cleanup_env
run_test "layer-apply-env-valid" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-set-policies --path '"${PIPELINE_LAYER_DIR}"' \
        --env-out "$TMP_OUT" >/dev/null && \
     grep -q "IGconf_setpol_alwaysset=default-value" "$TMP_OUT" && \
     grep -q "IGconf_setpol_defaultbehavior=default-value" "$TMP_OUT" && \
     rm -f "$TMP_ENV" "$TMP_OUT"' \
    0 \
    "Pipeline apply-env should work with valid metadata"


# Layer apply-env with invalid metadata
run_test "layer-apply-env-invalid" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-unsupported --path '"${PIPELINE_LAYER_DIR}"' \
        --env-out "$TMP_OUT" >/dev/null; \
     status=$?; rm -f "$TMP_ENV" "$TMP_OUT"; exit $status' \
    1 \
    "Pipeline apply-env should fail with invalid metadata"


# Verify meta parse auto-sets required variables with Set: y
cleanup_env
unset IGconf_net_interface
IGconf_net_interface_before=$(env | grep IGconf_net_interface || echo "UNSET")
# Temporarily change Set policy to y for this test
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${LAYERS}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml
run_test "meta-parse-sets-required-vars" \
    "test \"\$IGconf_net_interface_before\" = \"UNSET\" && ig metadata --parse ${LAYERS}/network-x-env.yaml | grep 'IGconf_net_interface=eth0'" \
    0 \
    "Meta parse should set required variables from defaults when Set: y"
# Restore original setting
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${LAYERS}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml



# Test layer apply-env sets variables instead of skipping them
cleanup_env
unset IGconf_net_interface IGconf_net_ip IGconf_net_dns
# Temporarily change Set policy to y for this test
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${LAYERS}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml
run_test "layer-apply-env-sets-vars" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers network-setup --path '"${PIPELINE_LAYER_DIR}"' \
        --env-out "$TMP_OUT" >/dev/null && \
     grep -q "^IGconf_net_interface=eth0$" "$TMP_OUT" && \
     grep -q "^IGconf_net_ip=192.168.1.100$" "$TMP_OUT" && \
     rm -f "$TMP_ENV" "$TMP_OUT"' \
    0 \
    "Pipeline should set network variables when unset"
# Restore original setting
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${LAYERS}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml


# Test metadata parse with required+auto-set variables works
cleanup_env
unset IGconf_net_interface IGconf_net_ip IGconf_net_dns
# Temporarily change Set policy to y for this test
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${LAYERS}/network-x-env.yaml
run_test "meta-parse-required-auto-set-regression" \
    "ig metadata --parse ${LAYERS}/network-x-env.yaml | grep 'IGconf_net_interface=eth0'" \
    0 \
    "Meta parse should work with required variables that have Set: y (regression test)"
# Restore original setting
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${LAYERS}/network-x-env.yaml


# Test both meta parse and layer apply-env work
cleanup_env
unset IGconf_net_interface IGconf_net_ip IGconf_net_dns
# Temporarily change Set policy to y for this test
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${LAYERS}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: n/X-Env-Var-INTERFACE-Set: y/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml
run_test "meta-parse-layer-apply-env-consistency" \
    'ig metadata --parse ${LAYERS}/network-x-env.yaml >/dev/null && \
     TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers network-setup --path '"${PIPELINE_LAYER_DIR}"' \
        --env-out "$TMP_OUT" >/dev/null && \
     grep -q "^IGconf_net_interface=eth0$" "$TMP_OUT" && \
     rm -f "$TMP_ENV" "$TMP_OUT"' \
    0 \
    "Both meta parse and layer apply-env should work consistently with required+auto-set variables"
# Restore original setting
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${LAYERS}/network-x-env.yaml
sed -i 's/X-Env-Var-INTERFACE-Set: y/X-Env-Var-INTERFACE-Set: n/' ${PIPELINE_LAYER_DIR}/network-x-env.yaml


# Test layer apply-env fails when required variable has Set: n and is not provided
cleanup_env
unset IGconf_net_interface IGconf_net_ip IGconf_net_dns
run_test "layer-apply-env-fails-required-no-set" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers network-setup --path '"${PIPELINE_LAYER_DIR}"' \
        --env-out "$TMP_OUT" >/dev/null; \
     status=$?; rm -f "$TMP_ENV" "$TMP_OUT"; exit $status' \
    1 \
    "Pipeline should fail when required variables are missing and Set: n"


# Test layer apply-env succeeds when required variable has Set: n but is provided
cleanup_env
unset IGconf_net_interface IGconf_net_ip IGconf_net_dns
export IGconf_net_interface=wlan0
run_test "layer-apply-env-succeeds-required-manually-set" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" "IGconf_net_interface=wlan0" && \
     ig pipeline --env-in "$TMP_ENV" --layers network-setup --path '"${PIPELINE_LAYER_DIR}"' \
        --env-out "$TMP_OUT" >/dev/null && \
     grep -q "^IGconf_net_interface=wlan0$" "$TMP_OUT" && \
     rm -f "$TMP_ENV" "$TMP_OUT"' \
    0 \
    "Pipeline should respect manually provided required variables"


# Test metadata parse fails when required variable has Set: n and is not provided
cleanup_env
unset IGconf_net_interface IGconf_net_ip IGconf_net_dns
run_test "meta-parse-fails-required-no-set" \
    "ig metadata --parse ${LAYERS}/network-x-env.yaml" \
    1 \
    "Meta parse should fail when required variables have Set: n and are not provided in environment"


# Test metadata parse succeeds when required variable has Set: n but is manually provided
cleanup_env
unset IGconf_net_interface IGconf_net_ip IGconf_net_dns
export IGconf_net_interface=wlan0
run_test "meta-parse-succeeds-required-manually-set" \
    "ig metadata --parse ${LAYERS}/network-x-env.yaml | grep 'IGconf_net_interface=wlan0'" \
    0 \
    "Meta parse should succeed when required variables have Set: n but are manually provided"


# Test lazy policy last-wins
cleanup_env
unset IGconf_lazy_path
run_test "lazy-last-wins" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-lazy-second --path '"${PIPELINE_LAYER_DIR}"' \
        --env-out "$TMP_OUT" >/dev/null && \
     grep -q "^IGconf_lazy_path=/usr/second$" "$TMP_OUT" && \
     rm -f "$TMP_ENV" "$TMP_OUT"' \
    0 \
    "Pipeline should apply lazy last-wins value from test-lazy-second"

# Test force policy overrides existing value
cleanup_env
export IGconf_force_color=red
run_test "force-overwrite" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" "IGconf_force_color=red" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-force-overwrite --path '"${PIPELINE_LAYER_DIR}"' \
        --env-out "$TMP_OUT" >/dev/null && \
     grep -q "^IGconf_force_color=blue$" "$TMP_OUT" && \
     rm -f "$TMP_ENV" "$TMP_OUT"' \
    0 \
    "Pipeline force policy should overwrite pre-existing env value"
cleanup_env

# Test placeholder substitution
cleanup_env
unset IGconf_placeholder_path
expected_dir="${LAYERS}"
run_test "placeholder-directory" \
   "ig metadata --parse ${LAYERS}/placeholder-test.yaml | grep \"IGconf_placeholder_path=${expected_dir}\"" \
   0 \
   "Placeholder ${DIRECTORY} should resolve to metadata directory"

# Test --write-out functionality
cleanup_env
unset IGconf_basic_hostname IGconf_basic_port
WRITE_TEST_FILE="/tmp/test-writeout-$$.env"
run_test "meta-parse-write-out" \
    "ig metadata --parse ${LAYERS}/valid-basic.yaml --write-out ${WRITE_TEST_FILE} >/dev/null && grep -q 'IGconf_basic_hostname=\"localhost\"' ${WRITE_TEST_FILE} && grep -q 'IGconf_basic_port=\"8080\"' ${WRITE_TEST_FILE}" \
    0 \
    "Meta parse --write-out should write variables to file"
rm -f ${WRITE_TEST_FILE}

# Pipeline should fail when lint errors are present
cleanup_env
run_test "pipeline-fails-on-lint-error" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ! ig pipeline --env-in "$TMP_ENV" --layers test-provider-consumer-missing --path '"${PIPELINE_LAYER_DIR}"' --env-out "$TMP_OUT" >/dev/null' \
    0 \
    "Pipeline should abort on lint/validation errors"

print_header "PIPELINE APPLY TESTS"

run_test "pipeline-write-env-basic" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-basic --path '"${PIPELINE_LAYER_DIR}"' --env-out "$TMP_OUT" && \
     grep -q "^IGconf_basic_hostname=localhost$" "$TMP_OUT" && \
     grep -q "^IGconf_basic_port=8080$" "$TMP_OUT" && \
     rm -f "$TMP_ENV" "$TMP_OUT"' \
    0 \
    "Pipeline should resolve vars for single layer"

run_test "pipeline-respects-existing-values" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" "IGconf_basic_hostname=already-set" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-basic --path '"${PIPELINE_LAYER_DIR}"' --env-out "$TMP_OUT" && \
     grep -q "^IGconf_basic_hostname=already-set$" "$TMP_OUT" && \
     grep -q "^IGconf_basic_port=8080$" "$TMP_OUT" && \
     rm -f "$TMP_ENV" "$TMP_OUT"' \
    0 \
    "Pipeline should not overwrite existing immediate-set values"

run_test "pipeline-multi-layer-write-env" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-basic test-all-types --path '"${PIPELINE_LAYER_DIR}"' --env-out "$TMP_OUT" && \
     grep -q "^IGconf_basic_hostname=localhost$" "$TMP_OUT" && \
     grep -q "^IGconf_types_name=myapp$" "$TMP_OUT" && \
     grep -q "^IGconf_types_timeout=30$" "$TMP_OUT" && \
     rm -f "$TMP_ENV" "$TMP_OUT"' \
    0 \
    "Pipeline should write vars from multiple layers"

run_test "pipeline-dependency-write-env" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-with-deps --path '"${PIPELINE_LAYER_DIR}"' --env-out "$TMP_OUT" && \
     grep -q "^IGconf_basic_hostname=localhost$" "$TMP_OUT" && \
     grep -q "^IGconf_deps_feature=enabled$" "$TMP_OUT" && \
     rm -f "$TMP_ENV" "$TMP_OUT"' \
    0 \
    "Pipeline should honor dependency expansion"

cleanup_env
run_test "provider-resolution" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && TMP_DIR=$(mktemp -d) && \
     cp '"${LAYERS}"'/provider-base.yaml "$TMP_DIR"/ && \
     cp '"${LAYERS}"'/provider-consumer.yaml "$TMP_DIR"/ && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-provider-base test-provider-consumer --path "$TMP_DIR" \
        --env-out "$TMP_OUT" >/dev/null && \
     rm -rf "$TMP_ENV" "$TMP_OUT" "$TMP_DIR"' \
    0 \
    "Provider check should pass if provider in dependency chain"

cleanup_env
run_test "provider-missing" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && TMP_DIR=$(mktemp -d) && \
     cp '"${LAYERS}"'/provider-consumer-missing.yaml "$TMP_DIR"/ && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-provider-consumer-missing --path "$TMP_DIR" \
        --env-out "$TMP_OUT" >/dev/null && \
     rm -rf "$TMP_ENV" "$TMP_OUT" "$TMP_DIR"' \
    1 \
    "Check should fail when provider capability not available"

cleanup_env
run_test "provider-conflict" \
    'TMP_ENV=$(mktemp -t provider-env.XXXXXX) && TMP_OUT=$(mktemp -t provider-out.XXXXXX) && TMP_DIR=$(mktemp -d) && \
     cat > "${TMP_DIR}/provider-conflict1.yaml" << "EOF" && \
     # METABEGIN
     # X-Env-Layer-Name: test-provider-conflict1
     # X-Env-Layer-Version: 1.0.0
     # X-Env-Layer-Provides: database
     # X-Env-Layer-Category: test
     # METAEND
EOF
     cat > "${TMP_DIR}/provider-conflict2.yaml" << "EOF" && \
     # METABEGIN
     # X-Env-Layer-Name: test-provider-conflict2
     # X-Env-Layer-Version: 1.0.0
     # X-Env-Layer-Provides: database
     # X-Env-Layer-Category: test
     # METAEND
EOF
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-provider-conflict1 test-provider-conflict2 --path "$TMP_DIR" \
        --env-out "$TMP_OUT" >/dev/null; RESULT=$?; \
     rm -rf "$TMP_ENV" "$TMP_OUT" "$TMP_DIR"; \
     exit $RESULT' \
    1 \
    "Check should fail when multiple layers provide the same capability"

cleanup_env

run_test "pipeline-build-order" \
    'TMP_ENV=$(mktemp) && TMP_ENV_OUT=$(mktemp) && TMP_ORDER=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-with-deps --path '"${PIPELINE_LAYER_DIR}"' \
        --env-out "$TMP_ENV_OUT" --order-out "$TMP_ORDER" >/dev/null && \
     grep -q "^test-basic=" "$TMP_ORDER" && \
     grep -q "^test-with-deps=" "$TMP_ORDER" && \
     rm -f "$TMP_ENV" "$TMP_ENV_OUT" "$TMP_ORDER"' \
    0 \
    "Pipeline should write build order for dependencies"

run_test "pipeline-build-order-env-deps" \
    'TMP_ENV=$(mktemp) && TMP_ENV_OUT=$(mktemp) && TMP_ORDER=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" "ARCH=arm64" "DISTRO=debian" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-env-var-deps --path '"${PIPELINE_LAYER_DIR}"' \
        --env-out "$TMP_ENV_OUT" --order-out "$TMP_ORDER" >/dev/null && \
     grep -q "^test-basic=" "$TMP_ORDER" && \
     grep -q "^arm64-toolchain=" "$TMP_ORDER" && \
     grep -q "^debian-packages=" "$TMP_ORDER" && \
     rm -f "$TMP_ENV" "$TMP_ENV_OUT" "$TMP_ORDER"' \
    0 \
    "Pipeline should resolve env-based deps and write build order"

run_test "bulk-lint-all-yaml" '
    # 1) collect only *.yaml that appear to contain X-Env metadata
    files=()
    while IFS= read -r -d "" f; do
        files+=("$f")
    done < <(find "${IGTOP}/layer" "${IGTOP}/device" "${IGTOP}/image" "${IGTOP}/examples" \
                 -type f -name "*.yaml" -print0 \
             | xargs -0 grep -lZ -E "(^|[[:space:]])X-Env-|^# METABEGIN" || true)

    total=${#files[@]}
    pass=0  fail=0  failed=()

    # 2) lint each file
    for f in "${files[@]}"; do
        filename=$(basename "$f")

        # Look for corresponding env file
        env_file="${IGTOP}/test/layer/env/dist/${filename}.env"

        # Run lint in a subshell with environment variables loaded
        if [[ -f "$env_file" ]]; then
            echo "Loading environment from: $env_file"
            if ( set -a; . "$env_file" && ig metadata --lint "$f" >/dev/null 2>&1 ); then
                ((pass++))
            else
                ((fail++))
                failed+=("$f")
            fi
        else
            # No env file, run normally
            if ig metadata --lint "$f" >/dev/null 2>&1; then
                ((pass++))
            else
                ((fail++))
                failed+=("$f")
            fi
        fi
    done

    # 3) show a short summary + any failures
    echo "Total: $total  OK: $pass  FAIL: $fail"
    if (( fail > 0 )); then
        printf "Failed files:\n%s\n" "${failed[@]}"
    fi

    # 4) success when every YAML passed
    [[ $pass -eq $total ]]
' 0 "All metadata-bearing YAML under layer/, device/, image/, examples/ must lint successfully"

# Test variable dependency ordering using three-layer dependency chain and shell sourcing
# This robust test catches ordering bugs by using shell strict mode to detect undefined variables
cleanup_env
run_test "variable-dependency-order-robust" \
    'TMP_ENV=$(mktemp) &&
     TMP_OUT=$(mktemp) &&
          make_pipeline_env "$TMP_ENV" &&
     ig pipeline --env-in "$TMP_ENV" --layers test-dependency-top --path '"${PIPELINE_LAYER_DIR}"' \
        --env-out "$TMP_OUT" >/dev/null 2>&1 &&
     env -i bash -c '\''
       set -aeu  # Strict mode: -a export all, -e exit on error, -u error on undefined vars
       source "$1"
       # Verify variables resolved correctly (force policy should override lazy)
       [[ "$IGconf_dep_base" == "/test/base/path" ]] &&
       [[ "$IGconf_dep_component" == "enhanced-core" ]] &&  # Force override
       [[ "$IGconf_dep_service" == "enhanced-core-service" ]] &&  # Uses force value  
       [[ "$IGconf_dep_configpath" == "/test/base/path/config" ]] &&
       [[ "$IGconf_dep_finalpath" == "/test/base/path/enhanced-core-service/final" ]] &&
       [[ "$IGconf_dep_result" == "/test/base/path/config/enhanced-core/result" ]]
     '\'' _ "$TMP_OUT" &&
     rm -f "$TMP_ENV" "$TMP_OUT"' \
    0 \
    "Variables should be in correct dependency order and shell-sourceable with strict error checking"


print_header "ENVIRONMENT VARIABLE DEPENDENCY TESTS"

# Test environment variable dependency apply-env
cleanup_env
export ARCH=arm64
export DISTRO=debian
run_test "env-var-deps-apply-env" \
    'TMP_ENV=$(mktemp) && TMP_OUT=$(mktemp) && \
     make_pipeline_env "$TMP_ENV" && \
     ig pipeline --env-in "$TMP_ENV" --layers test-env-var-deps --path '"${PIPELINE_LAYER_DIR}"' \
        --env-out "$TMP_OUT" >/dev/null && \
     grep -q "^IGconf_envtest_feature=enabled$" "$TMP_OUT" && \
     rm -f "$TMP_ENV" "$TMP_OUT"' \
    0 \
    "Environment variable dependencies should work with pipeline apply-env"

print_header "LAYER MANAGER TESTS"

run_test "layer-manager-dynamic-generation" \
    "python3 ${LAYERS}/test_dynamic_layer_manager.py" \
    0 \
    "LayerManager should generate dynamic layers into dynamic root"

print_summary
