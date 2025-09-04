#!/bin/bash

# Simple test runner for debugging

echo "=== Simple Plugin Test ==="

# Set up environment
export BUILDKITE_COMMAND_EXIT_STATUS=0
export BUILDKITE_BUILD_ID="test-build-123"
export BUILDKITE_PIPELINE_SLUG="test-pipeline"
export BUILDKITE_REPO="jellyfish-ai/test-repo"
export BUILDKITE_BUILD_URL="https://buildkite.com/test/builds/123"
export BUILDKITE_COMMIT="abc123"
export BUILDKITE_BUILD_NUMBER="123"
export BUILDKITE_PLUGIN_JELLYFISH_WEBHOOK_URL="https://httpbin.org/post"
export BUILDKITE_PLUGIN_JELLYFISH_API_TOKEN="test-token"

echo "Testing basic functionality..."
../post-command.sh
echo "Exit code: $?"

echo ""
echo "Testing with labels..."
export BUILDKITE_PLUGIN_JELLYFISH_LABELS="env:test service:api"
../post-command.sh
echo "Exit code: $?"

echo ""
echo "Testing failed build (should skip)..."
export BUILDKITE_COMMAND_EXIT_STATUS=1
../post-command.sh
echo "Exit code: $?"

echo ""
echo "Testing missing webhook URL (should fail)..."
export BUILDKITE_COMMAND_EXIT_STATUS=0
unset BUILDKITE_PLUGIN_JELLYFISH_WEBHOOK_URL
../post-command.sh
echo "Exit code: $?"
