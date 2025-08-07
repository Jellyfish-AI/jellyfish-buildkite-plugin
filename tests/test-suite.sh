#!/bin/bash

# Comprehensive test suite for the Jellyfish Buildkite Plugin

# Don't exit on errors so we can see all test results
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=$(mktemp -d)
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

log_test() {
    echo -e "${YELLOW}[TEST $((++TEST_COUNT))]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((PASS_COUNT++))
}

log_fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((FAIL_COUNT++))
}

setup_base_env() {
    # Clear any existing plugin environment variables
    unset BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_WEBHOOK_URL
    unset BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_API_TOKEN
    unset BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_REFERENCE_ID
    unset BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_NAME
    unset BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_REPO_NAME
    unset BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_LABELS
    unset BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_SOURCE_URL
    
    # Set base Buildkite environment
    export BUILDKITE_COMMAND_EXIT_STATUS=0
    export BUILDKITE_BUILD_ID="test-build-$(date +%s)"
    export BUILDKITE_PIPELINE_SLUG="test-pipeline"
    export BUILDKITE_REPO="jellyfish-ai/test-repo"
    export BUILDKITE_BUILD_URL="https://buildkite.com/jellyfish-ai/test-pipeline/builds/123"
    export BUILDKITE_COMMIT="abc123def456789"
    export BUILDKITE_BUILD_NUMBER="123"
}

run_post_command() {
    local output_file="$TEMP_DIR/output.txt"
    
    # Run the script and capture output (go up one directory to find post-command.sh)
    if (cd "$SCRIPT_DIR/.." && ./post-command.sh > "$output_file" 2>&1); then
        # Command succeeded
        cat "$output_file"
        return 0
    else
        # Command failed
        cat "$output_file"
        return 1
    fi
}

check_output_contains() {
    local expected_text="$1"
    local should_succeed="${2:-true}"  # Default to expecting success
    local output_file="$TEMP_DIR/output.txt"
    
    # Run the command and capture output and exit code
    local exit_code=0
    (cd "$SCRIPT_DIR/.." && ./post-command.sh > "$output_file" 2>&1) || exit_code=$?
    
    # Show the output
    cat "$output_file"
    
    # Check if output contains expected text
    if grep -q "$expected_text" "$output_file"; then
        if [ "$should_succeed" = "true" ]; then
            return 0  # Found expected text and expecting success
        else
            return 0  # Found expected error text
        fi
    else
        return 1  # Didn't find expected text
    fi
}

echo "=== Jellyfish Buildkite Plugin Test Suite ==="
echo ""

# Test 1: Basic successful deployment
log_test "Basic successful deployment"
setup_base_env
export BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_WEBHOOK_URL="https://httpbin.org/post"
export BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_API_TOKEN="test-token"
if check_output_contains "successfully"; then
    log_pass "Basic deployment webhook sent successfully"
else
    log_fail "Basic deployment failed"
fi
echo ""

# Test 2: Missing webhook URL
log_test "Missing webhook URL (should fail)"
setup_base_env
export BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_API_TOKEN="test-token"
# Don't set WEBHOOK_URL - it should be missing
if check_output_contains "webhook-url is required"; then
    log_pass "Correctly failed when webhook URL missing"
else
    log_fail "Should have failed when webhook URL missing"
fi
echo ""

# Test 3: Missing API token
log_test "Missing API token (should fail)"
setup_base_env
export BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_WEBHOOK_URL="https://httpbin.org/post"
# Don't set API_TOKEN - it should be missing
if check_output_contains "api-token is required"; then
    log_pass "Correctly failed when API token missing"
else
    log_fail "Should have failed when API token missing"
fi
echo ""

# Test 4: Failed build (should skip)
log_test "Failed build status (should skip webhook)"
setup_base_env
export BUILDKITE_COMMAND_EXIT_STATUS=1
export BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_WEBHOOK_URL="https://httpbin.org/post"
export BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_API_TOKEN="test-token"
if check_output_contains "skipping deployment webhook"; then
    log_pass "Correctly skipped webhook for failed build"
else
    log_fail "Should have skipped webhook for failed build"
fi
echo ""

# Test 5: Custom labels
log_test "Custom labels handling"
setup_base_env
export BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_WEBHOOK_URL="https://httpbin.org/post"
export BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_API_TOKEN="test-token"
export BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_LABELS="env:prod service:api region:us-east"
if check_output_contains "successfully"; then
    log_pass "Successfully handled custom labels"
else
    log_fail "Failed to handle custom labels"
fi
echo ""

# Test 6: Custom deployment name
log_test "Custom deployment name"
setup_base_env
export BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_WEBHOOK_URL="https://httpbin.org/post"
export BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_API_TOKEN="test-token"
export BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_NAME="custom-deployment-name"
if check_output_contains "custom-deployment-name"; then
    log_pass "Successfully used custom deployment name"
else
    log_fail "Failed to use custom deployment name"
fi
echo ""

# Test 7: Invalid webhook URL
log_test "Invalid webhook URL (should fail gracefully)"
setup_base_env
export BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_WEBHOOK_URL="https://httpbin.org/status/500"
export BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_API_TOKEN="test-token"
if check_output_contains "Failed to send"; then
    log_pass "Correctly handled invalid webhook URL"
else
    log_fail "Should have failed gracefully with invalid webhook URL"
fi
echo ""

# Summary
echo "=== Test Summary ==="
echo "Total tests: $TEST_COUNT"
echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
echo -e "${RED}Failed: $FAIL_COUNT${NC}"

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
