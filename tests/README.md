# Testing Guide for Jellyfish Buildkite Plugin

This directory contains all test scripts and comprehensive testing documentation for the Jellyfish Buildkite Plugin.

## Quick Start

From the root directory, run:

```bash
# Run all tests
./test.sh

# Or run specific test types
./test.sh --quick      # Quick local test
./test.sh --full       # Comprehensive test suite
./test.sh --payload    # JSON payload validation
./test.sh --help       # Show all options
```

## Test Files

| File | Description |
|------|-------------|
| `test-local.sh` | Quick local test with mock Buildkite environment |
| `test-suite.sh` | Comprehensive test suite covering all scenarios |
| `simple-test.sh` | Simple manual testing script for debugging |
| `test-payload.sh` | JSON payload validation and HTTP endpoint testing |

## Testing Methods

### 1. Local Script Testing (Recommended for Development)

Run the provided test script to simulate a Buildkite environment:

```bash
# From root directory
./test.sh --quick

# Or from tests directory
cd tests/
./test-local.sh
```

This script:
- Sets up mock Buildkite environment variables
- Runs the post-command script 
- Sends a test webhook to httpbin.org
- Shows the complete flow with logging

### 2. Comprehensive Test Suite

Run all test scenarios:

```bash
# From root directory
./test.sh --full

# Or from tests directory
cd tests/
./test-suite.sh
```

This tests:
- ✅ Successful deployment flow
- ✅ Missing required parameters
- ✅ Failed build handling (skipping webhook)
- ✅ Custom labels processing
- ✅ Error handling for network issues

### 3. JSON Payload Validation

Validate the JSON structure:

```bash
# From root directory
./test.sh --payload

# Or from tests directory
cd tests/
./test-payload.sh
```

## Manual Testing Methods

### Method 1: Direct Script Testing

```bash
# Set up environment variables manually
export BUILDKITE_COMMAND_EXIT_STATUS=0
export BUILDKITE_BUILD_ID="test-build-123"
export BUILDKITE_PIPELINE_SLUG="my-test-pipeline"
export BUILDKITE_REPO="my-org/my-repo"
export BUILDKITE_BUILD_URL="https://buildkite.com/my-org/my-pipeline/builds/123"
export BUILDKITE_COMMIT="abc123def456" # pragma: allowlist secret
export BUILDKITE_BUILD_NUMBER="123"

# Plugin configuration
export BUILDKITE_PLUGIN_JELLYFISH_WEBHOOK_URL="https://your-test-endpoint.com/webhook"
export BUILDKITE_PLUGIN_JELLYFISH_API_TOKEN="your-test-token"
export BUILDKITE_PLUGIN_JELLYFISH_LABELS="environment:staging service:api"

# Run the script
../post-command.sh
```

### Method 2: Using webhook.site for Real HTTP Testing

1. Go to https://webhook.site/
2. Copy your unique URL
3. Use it as the webhook URL in tests:

```bash
export BUILDKITE_PLUGIN_JELLYFISH_WEBHOOK_URL="https://webhook.site/your-unique-id"
./test-local.sh
```

4. Check the webhook.site page to see the received payload

### Method 3: Using httpbin.org

Test different HTTP scenarios:

```bash
# Test successful POST
export BUILDKITE_PLUGIN_JELLYFISH_WEBHOOK_URL="https://httpbin.org/post"

# Test 404 error
export BUILDKITE_PLUGIN_JELLYFISH_WEBHOOK_URL="https://httpbin.org/status/404"

# Test 500 error  
export BUILDKITE_PLUGIN_JELLYFISH_WEBHOOK_URL="https://httpbin.org/status/500"
```

## Testing in Real Buildkite Pipeline

### Step 1: Create a Test Pipeline

Create a `.buildkite/pipeline.yml` in a test repository:

```yaml
env:
  JELLYFISH_API_TOKEN: "your-test-token"

steps:
  - label: ":test_tube: Test Plugin"
    command: |
      echo "This is a test deployment"
      echo "Deploy completed successfully"
    plugins:
      - jellyfish:
          webhook-url: "https://webhook.site/your-unique-id"
          api-token: "${JELLYFISH_API_TOKEN}"
          name: "test-deployment"
          labels:
            - "environment:test"
            - "service:plugin-test"
```

### Step 2: Test Different Scenarios

Create multiple steps to test different cases:

```yaml
steps:
  # Test successful deployment
  - label: ":white_check_mark: Successful Deploy"
    command: "echo 'Success!' && exit 0"
    plugins:
      - jellyfish:
          webhook-url: "https://webhook.site/your-unique-id"
          api-token: "${JELLYFISH_API_TOKEN}"
          name: "successful-deployment"

  # Test failed deployment (should skip webhook)
  - label: ":x: Failed Deploy"
    command: "echo 'Failed!' && exit 1"
    plugins:
      - jellyfish:
          webhook-url: "https://webhook.site/your-unique-id"
          api-token: "${JELLYFISH_API_TOKEN}"
          name: "failed-deployment"
```

## Test Coverage

The test suite covers:

- ✅ **Basic Functionality**: Successful deployment webhook sending
- ✅ **Error Handling**: Missing configuration parameters
- ✅ **Build Status**: Failed builds are properly skipped
- ✅ **Custom Configuration**: Labels, names, and other optional parameters
- ✅ **Network Issues**: Invalid URLs and HTTP error responses
- ✅ **JSON Structure**: Payload format validation
- ✅ **Environment Variables**: Buildkite variable integration

## Expected Test Results

### Successful Deployment

Expected output:
```
--- :rocket: Sending deployment webhook to Jellyfish...
--- :information_source: Sending deployment data for: my-deployment (commit: abc123)
--- :white_check_mark: Deployment webhook sent successfully to Jellyfish! (HTTP 200)
```

Expected JSON payload:
```json
{
  "reference_id": "build-123",
  "is_successful": true,
  "name": "my-deployment",
  "deployed_at": "2025-08-07T12:34:56Z",
  "repo_name": "my-org/my-repo",
  "commit_shas": ["abc123def456"],
  "labels": ["environment:production", "service:api"],
  "source_url": "https://buildkite.com/my-org/pipeline/builds/123"
}
```

### Failed Build (Should Skip)

Expected output:
```
--- :x: Build command failed (1), skipping deployment webhook.
```

### Missing Configuration

Expected output:
```
--- :x: Error: webhook-url is required but not provided.
```

## Dependencies

Tests require:
- `bash` (version 4+)
- `curl` 
- `jq`
- `timeout` command (usually available on Linux/macOS)

## Output Examples

### Successful Test
```
🧪 Jellyfish Buildkite Plugin Test Runner

🔍 Checking dependencies...
✅ Dependencies OK

=== Running Quick Local Test ===
--- :rocket: Sending deployment webhook to Jellyfish...
--- :information_source: Sending deployment data for: test-deployment (commit: abc123def456789)
--- :white_check_mark: Deployment webhook sent successfully to Jellyfish! (HTTP 200)
```

### Failed Test
```
=== Jellyfish Buildkite Plugin Test Suite ===

[TEST 1] Basic successful deployment
❌ FAIL: Basic deployment failed

[TEST 2] Missing webhook URL (should fail)
✅ PASS: Correctly failed when webhook URL missing
```

## Adding New Tests

To add a new test scenario:

1. Add the test case to `test-suite.sh`:
```bash
# Test N: Your new test
log_test "Your test description"
setup_base_env
# Set up specific test conditions
export BUILDKITE_PLUGIN_JELLYFISH_WEBHOOK_URL="test-url"
if run_post_command | grep -q "expected-output"; then
    log_pass "Test passed"
else
    log_fail "Test failed"
fi
```

2. Test it:
```bash
./test.sh --full
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Make sure scripts are executable
   ```bash
   chmod +x tests/*.sh
   chmod +x post-command.sh
   ```

2. **Path Issues**: Tests expect to be run from the tests directory or via the main test runner

3. **Missing Dependencies**: Install curl and jq
   ```bash
   # macOS
   brew install curl jq
   
   # Ubuntu/Debian  
   apt-get install curl jq
   ```

4. **Environment Variables**: Double-check variable names match exactly
   - Plugin variables must start with `BUILDKITE_PLUGIN_JELLYFISH_`
   - Use underscores, not hyphens in environment variable names

5. **JSON Validation Errors**: Test JSON generation separately
   ```bash
   ./test-payload.sh
   ```

6. **Timeout Issues**: Some tests use network requests that may timeout on slow connections

### Debug Mode

For verbose output, modify test scripts to add:
```bash
set -x  # Enable debug mode
```

Add debug logging to see all variables:
```bash
# Add this to post-command.sh for debugging
echo "DEBUG: All plugin environment variables:"
env | grep BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN || echo "No plugin variables found"
```

### Testing with Real Endpoints

Replace test URLs with real webhook endpoints:
- Use https://webhook.site/ for inspecting payloads
- Use https://httpbin.org/ for testing HTTP responses
- Use your actual Jellyfish webhook URL for integration testing

## Testing Checklist

Before considering the plugin ready:

- [ ] ✅ Local tests pass (`./test.sh --quick`)
- [ ] ✅ Comprehensive test suite passes (`./test.sh --full`)
- [ ] ✅ JSON payload is valid (`./test.sh --payload`)
- [ ] ✅ Successful deployment sends webhook
- [ ] ✅ Failed builds skip webhook
- [ ] ✅ Missing required config shows error
- [ ] ✅ Network errors are handled gracefully
- [ ] ✅ Custom labels are processed correctly
- [ ] ✅ All Buildkite environment variables work as defaults
- [ ] ✅ Plugin works in real Buildkite pipeline

## Next Steps

1. **Local Testing**: Start with `./test.sh --quick`
2. **Integration Testing**: Test with real webhook endpoints
3. **Pipeline Testing**: Create a test Buildkite pipeline
4. **Production Testing**: Deploy to staging environment first
5. **Documentation**: Update examples with real webhook URLs
