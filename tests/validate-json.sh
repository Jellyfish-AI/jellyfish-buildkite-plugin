#!/bin/bash

export BUILDKITE_COMMAND_EXIT_STATUS=0
export BUILDKITE_BUILD_ID="test-build-123"
export BUILDKITE_PIPELINE_SLUG="test-pipeline"
export BUILDKITE_REPO="jellyfish-ai/test-repo"
export BUILDKITE_BUILD_URL="https://buildkite.com/test/builds/123"
export BUILDKITE_COMMIT="abc123"
export BUILDKITE_BUILD_NUMBER="123"
export BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_LABELS="environment:test service:api region:us-east"

REFERENCE_ID="test-build-123"
DEPLOYMENT_NAME="test-pipeline"
REPO_NAME="jellyfish-ai/test-repo"
SOURCE_URL="https://buildkite.com/test/builds/123"
IS_SUCCESSFUL="true"
DEPLOYED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
COMMIT_SHAS='["abc123"]' # pragma: allowlist secret
LABELS_JSON_ARRAY=$(echo "environment:test service:api region:us-east" | jq -R -s 'split(" ") | map(select(length > 0))')

JSON_PAYLOAD=$(jq -n \
  --arg ref_id "$REFERENCE_ID" \
  --arg is_success "$IS_SUCCESSFUL" \
  --arg name "$DEPLOYMENT_NAME" \
  --arg deployed_at "$DEPLOYED_AT" \
  --arg repo_name "$REPO_NAME" \
  --argjson commit_shas "$COMMIT_SHAS" \
  --argjson labels "$LABELS_JSON_ARRAY" \
  --arg source_url "$SOURCE_URL" \
  '{
    "reference_id": $ref_id,
    "is_successful": ($is_success | fromjson),
    "name": $name,
    "deployed_at": $deployed_at,
    "repo_name": $repo_name,
    "commit_shas": $commit_shas,
    "labels": $labels,
    "source_url": $source_url
  }')

echo "Generated JSON payload:"
echo "$JSON_PAYLOAD" | jq .

echo ""
echo "JSON validation:"
if echo "$JSON_PAYLOAD" | jq . > /dev/null 2>&1; then
    echo "✅ JSON is valid"
else
    echo "❌ JSON is invalid"
fi
