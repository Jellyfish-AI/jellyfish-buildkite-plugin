#!/bin/bash

set -euo pipefail  # Exit on errors, undefined variables, and pipe failures

# Exit if the previous command failed (BUILDKITE_COMMAND_EXIT_STATUS is non-zero)
if [ "$BUILDKITE_COMMAND_EXIT_STATUS" -ne 0 ]; then
  echo "--- :x: Build command failed ($BUILDKITE_COMMAND_EXIT_STATUS), skipping deployment webhook."
  exit 0
fi

echo "--- :rocket: Sending deployment webhook to Jellyfish..."

echo "--- :bug: Early Debug - Script started successfully"

# Retrieve plugin configuration values.
# Buildkite exposes plugin configuration as environment variables
# prefixed with BUILDKITE_PLUGIN_{PLUGIN_SLUG}_{OPTION_NAME}.
WEBHOOK_URL="${BUILDKITE_PLUGIN_JELLYFISH_WEBHOOK_URL:-}"
API_TOKEN="${BUILDKITE_PLUGIN_JELLYFISH_API_TOKEN:-}"

echo "--- :bug: Early Debug - Variables retrieved"
echo "WEBHOOK_URL set: $([ -n "$WEBHOOK_URL" ] && echo 'YES' || echo 'NO')"
echo "API_TOKEN set: $([ -n "$API_TOKEN" ] && echo 'YES' || echo 'NO')"

# Process labels: Buildkite passes array options as a space-separated string.
# We use 'jq' to convert this into a proper JSON array.
LABELS_JSON_ARRAY="[]"
if [ -n "${BUILDKITE_PLUGIN_JELLYFISH_LABELS:-}" ]; then
  LABELS_JSON_ARRAY=$(echo "$BUILDKITE_PLUGIN_JELLYFISH_LABELS" | jq -R -s 'split(" ") | map(select(length > 0))')
fi

# Validate required configuration
if [ -z "$WEBHOOK_URL" ]; then
  echo "--- :x: Error: webhook-url is required but not provided."
  exit 1
fi

if [ -z "$API_TOKEN" ]; then
  echo "--- :x: Error: api-token is required but not provided."
  exit 1
fi

# Use provided values or fall back to Buildkite environment variables.
REFERENCE_ID="${BUILDKITE_PLUGIN_JELLYFISH_REFERENCE_ID:-$BUILDKITE_BUILD_ID}"
DEPLOYMENT_NAME="${BUILDKITE_PLUGIN_JELLYFISH_NAME:-$BUILDKITE_PIPELINE_SLUG}"
REPO_NAME="${BUILDKITE_PLUGIN_JELLYFISH_REPO_NAME:-$BUILDKITE_REPO}"
SOURCE_URL="${BUILDKITE_PLUGIN_JELLYFISH_SOURCE_URL:-$BUILDKITE_BUILD_URL}"

# Dynamically generated data for the payload.
IS_SUCCESSFUL="true" # This hook only runs on success
DEPLOYED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ") # Current UTC time in ISO 8601 format
COMMIT_SHAS="[\"$BUILDKITE_COMMIT\"]" # Using the head commit of the build

# Process labels: Buildkite passes array options as a space-separated string.
# We use 'jq' to convert this into a proper JSON array.
LABELS_JSON_ARRAY="[]"
if [ -n "${BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_LABELS:-}" ]; then
  LABELS_JSON_ARRAY=$(echo "$BUILDKITE_PLUGIN_JELLYFISH_BUILDKITE_PLUGIN_LABELS" | jq -R -s 'split(" ") | map(select(length > 0))')
fi

# Construct the JSON payload.
# We use printf and jq to safely escape and format the JSON string.
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
    "is_successful": ($is_success | fromjson), # Convert "true" string to boolean true
    "name": $name,
    "deployed_at": $deployed_at,
    "repo_name": $repo_name,
    "commit_shas": $commit_shas,
    "labels": $labels,
    "source_url": $source_url
  }')

# Validate the JSON payload was constructed successfully
if [ $? -ne 0 ] || [ -z "$JSON_PAYLOAD" ]; then
  echo "--- :x: Error: Failed to construct JSON payload"
  exit 1
fi

echo "--- :bug: JSON payload constructed successfully"
echo "--- :information_source: Sending deployment data for: $DEPLOYMENT_NAME (commit: $BUILDKITE_COMMIT)"

# Debug output
echo "--- :bug: Debug Information:"
echo "Webhook URL: $WEBHOOK_URL"
echo "API Token (first 10 chars): ${API_TOKEN:0:10}..."
echo "API Token length: ${#API_TOKEN}"
echo "JSON Payload:"
echo "$JSON_PAYLOAD" | jq '.'

# Send the curl request to the webhook URL.
# -s: Silent mode (don't show progress or error messages)
# -w: Write out HTTP response code
# -X POST: Specify POST method
# -H: Add custom headers
# -d: Send data in the request body
echo "--- :outbox_tray: Sending request..."
echo "--- :bug: About to execute curl command"

HTTP_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -H "X-jf-api-token: $API_TOKEN" \
  -d "$JSON_PAYLOAD")

echo "--- :bug: Curl command completed"

# Extract HTTP status code (last 3 characters)
HTTP_STATUS="${HTTP_RESPONSE: -3}"

echo "--- :mag: Response received:"
echo "HTTP Status: $HTTP_STATUS"
echo "Full response: ${HTTP_RESPONSE%???}"  # Response without status code

# Check the HTTP response
if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 201 ] || [ "$HTTP_STATUS" -eq 202 ]; then
  echo "--- :white_check_mark: Deployment webhook sent successfully to Jellyfish! (HTTP $HTTP_STATUS)"
else
  echo "--- :warning: Failed to send deployment webhook to Jellyfish. HTTP status: $HTTP_STATUS"
  echo "--- :exclamation: Debugging - Full curl command (token redacted):"
  echo "curl -X POST '$WEBHOOK_URL' -H 'Content-Type: application/json' -H 'X-jf-api-token: [REDACTED]' -d '$JSON_PAYLOAD'"
  exit 1
fi