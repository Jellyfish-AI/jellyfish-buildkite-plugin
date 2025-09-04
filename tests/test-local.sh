#!/bin/bash

# Local testing script for the Jellyfish Buildkite Plugin
# This simulates the Buildkite environment to test the post-command script

set -e

echo "=== Testing Jellyfish Buildkite Plugin Locally ==="

# Mock Buildkite environment variables
export BUILDKITE_COMMAND_EXIT_STATUS=0
export BUILDKITE_BUILD_ID="test-build-$(date +%s)"
export BUILDKITE_PIPELINE_SLUG="test-pipeline"
export BUILDKITE_REPO="jellyfish-ai/test-repo"
export BUILDKITE_BUILD_URL="https://buildkite.com/jellyfish-ai/test-pipeline/builds/123"
export BUILDKITE_COMMIT="abc123def456789" # pragma: allowlist secret
export BUILDKITE_BUILD_NUMBER="123"

# Mock plugin configuration (these would normally come from pipeline.yml)
export BUILDKITE_PLUGIN_JELLYFISH_WEBHOOK_URL="https://httpbin.org/post"
export BUILDKITE_PLUGIN_JELLYFISH_API_TOKEN="test-api-token-12345"
export BUILDKITE_PLUGIN_JELLYFISH_NAME="test-deployment"
export BUILDKITE_PLUGIN_JELLYFISH_LABELS="environment:test service:api region:local"

echo "Environment variables set:"
echo "  BUILDKITE_BUILD_ID: $BUILDKITE_BUILD_ID"
echo "  BUILDKITE_PIPELINE_SLUG: $BUILDKITE_PIPELINE_SLUG"
echo "  BUILDKITE_REPO: $BUILDKITE_REPO"
echo "  BUILDKITE_COMMIT: $BUILDKITE_COMMIT"
echo "  Plugin webhook URL: $BUILDKITE_PLUGIN_JELLYFISH_WEBHOOK_URL"
echo "  Plugin labels: $BUILDKITE_PLUGIN_JELLYFISH_LABELS"
echo ""

echo "=== Running post-command script ==="
../post-command.sh

echo ""
echo "=== Test completed! ==="
echo "Check the output above for any errors."
echo "The request was sent to httpbin.org which will echo back the payload."
