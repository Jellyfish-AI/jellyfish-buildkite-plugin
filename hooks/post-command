#!/bin/bash

set -euo pipefail  # Exit on errors, undefined variables, and pipe failures

# Exit if the previous command failed (BUILDKITE_COMMAND_EXIT_STATUS is non-zero)
if [ "$BUILDKITE_COMMAND_EXIT_STATUS" -ne 0 ]; then
  echo "--- :x: Build command failed ($BUILDKITE_COMMAND_EXIT_STATUS), skipping deployment webhook."
  exit 0
fi

echo "--- :rocket: Sending deployment webhook to Jellyfish..."

# Retrieve plugin configuration values.
# Buildkite exposes plugin configuration as environment variables
# prefixed with BUILDKITE_PLUGIN_{PLUGIN_SLUG}_{OPTION_NAME}.
WEBHOOK_URL="${BUILDKITE_PLUGIN_JELLYFISH_WEBHOOK_URL:-}"
API_TOKEN="${BUILDKITE_PLUGIN_JELLYFISH_API_TOKEN:-}"

# Process labels: Buildkite passes array options as indexed environment variables.
# We collect all BUILDKITE_PLUGIN_JELLYFISH_LABELS_* variables and convert to JSON array.
LABELS_JSON_ARRAY="[]"
LABELS_LIST=""

# Collect all indexed label variables (LABELS_0, LABELS_1, etc.)
for var in $(env | grep "^BUILDKITE_PLUGIN_JELLYFISH_LABELS_[0-9]" | sort -V); do
  label_value=$(echo "$var" | cut -d'=' -f2-)
  if [ -n "$label_value" ]; then
    if [ -z "$LABELS_LIST" ]; then
      LABELS_LIST="$label_value"
    else
      LABELS_LIST="$LABELS_LIST $label_value"
    fi
  fi
done

# Convert collected labels to JSON array
if [ -n "$LABELS_LIST" ]; then
  LABELS_JSON_ARRAY=$(printf "%s" "$LABELS_LIST" | jq -R 'split(" ") | map(select(length > 0))')
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
SOURCE_URL="${BUILDKITE_PLUGIN_JELLYFISH_SOURCE_URL:-$BUILDKITE_BUILD_URL}"

# Process repo_name: Extract org/repo format from repository URL
REPO_NAME="${BUILDKITE_PLUGIN_JELLYFISH_REPO_NAME:-}"
if [ -z "$REPO_NAME" ]; then
  # Extract org/repo from BUILDKITE_REPO URL (e.g., https://github.com/org/repo -> org/repo)
  REPO_NAME=$(echo "$BUILDKITE_REPO" | sed -E 's|.*[:/]([^/]+/[^/]+)/?$|\1|' | sed 's/\.git$//')
fi

# Dynamically generated data for the payload.
IS_SUCCESSFUL="true" # This hook only runs on success
DEPLOYED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ") # Current UTC time in ISO 8601 format
COMMIT_SHAS="[\"$BUILDKITE_COMMIT\"]" # Using the head commit of the build



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

echo "--- :information_source: Sending deployment data for: $DEPLOYMENT_NAME (commit: $BUILDKITE_COMMIT)"

# Send the curl request to the webhook URL.
# -s: Silent mode (don't show progress or error messages)
# -w: Write out HTTP response code
# -X POST: Specify POST method
# -H: Add custom headers
# -d: Send data in the request body
HTTP_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -H "X-jf-api-token: $API_TOKEN" \
  -d "$JSON_PAYLOAD")

# Extract HTTP status code (last 3 characters)
HTTP_STATUS="${HTTP_RESPONSE: -3}"

# Check the HTTP response
if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 201 ] || [ "$HTTP_STATUS" -eq 202 ] || [ "$HTTP_STATUS" -eq 204 ]; then
  echo "--- :white_check_mark: Deployment webhook sent successfully to Jellyfish! (HTTP $HTTP_STATUS)"
else
  echo "--- :warning: Failed to send deployment webhook to Jellyfish. HTTP status: $HTTP_STATUS"
  echo "Response: ${HTTP_RESPONSE%???}"  # Remove last 3 characters (status code)
  exit 1
fi