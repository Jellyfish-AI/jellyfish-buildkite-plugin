# Jellyfish Buildkite Plugin

A Buildkite plugin that automatically sends deployment events to Jellyfish's DevOps API after successful builds. This enables seamless integration between your Buildkite CI/CD pipelines and Jellyfish's deployment tracking system.

## Features

- 🚀 Automatically triggers on successful builds
- 📊 Sends structured deployment data to Jellyfish
- 🏷️ Supports custom labels and metadata
- ⚡ Uses efficient post-command hooks
- 🔒 Secure API token authentication

## Usage

Add the plugin to your Buildkite pipeline's `pipeline.yml`:

```yaml
steps:
  - label: "Deploy to Production"
    command: "./deploy.sh"
    plugins:
      - jellyfish#v1.0.0:
          webhook-url: "https://webhooks.jellyfish.co/deployment"
          api-token: "${JELLYFISH_API_TOKEN}"
          name: "production-deployment"
          labels:
            - "environment:production"
            - "service:api"
            - "region:us-east-1"
```

## Configuration

### Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `webhook-url` | string | The Jellyfish deployment webhook URL |
| `api-token` | string | Your Jellyfish API token for authentication |

### Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `reference-id` | string | `$BUILDKITE_BUILD_ID` | Unique identifier for this deployment |
| `name` | string | `$BUILDKITE_PIPELINE_SLUG` | Name of the deployment |
| `repo-name` | string | `$BUILDKITE_REPO` | Repository name (e.g., 'org/repo') |
| `labels` | array | `[]` | List of labels for categorizing the deployment |
| `source-url` | string | `$BUILDKITE_BUILD_URL` | URL to the source/build that triggered this deployment |

## Payload Structure

The plugin sends a JSON payload with the following structure:

```json
{
  "reference_id": "build-123",
  "is_successful": true,
  "name": "my-service-deployment",
  "deployed_at": "2025-08-07T12:34:56Z",
  "repo_name": "org/my-repo",
  "commit_shas": ["abc123def456"], // pragma: allowlist secret
  "labels": ["environment:production", "service:api"],
  "source_url": "https://buildkite.com/org/pipeline/builds/123"
}
```

## Environment Variables

The plugin automatically uses the following Buildkite environment variables as defaults:

- `BUILDKITE_BUILD_ID` - For `reference_id`
- `BUILDKITE_PIPELINE_SLUG` - For deployment `name`
- `BUILDKITE_REPO` - For `repo_name`
- `BUILDKITE_BUILD_URL` - For `source_url`
- `BUILDKITE_COMMIT` - For `commit_shas`

## Security

- Store your Jellyfish API token as a secure environment variable
- The plugin only sends data on successful builds (non-zero exit codes are skipped)
- All data is sent over HTTPS to Jellyfish's secure endpoints

## Requirements

The plugin requires the following tools to be available on your Buildkite agents:

- `curl` - For HTTP requests
- `jq` - For JSON processing

## Examples

### Basic Usage
```yaml
plugins:
  - jellyfish#v1.0.0:
      webhook-url: "https://webhooks.jellyfish.co/deployment"
      api-token: "${JELLYFISH_API_TOKEN}"
```

### Advanced Usage with Custom Labels
```yaml
plugins:
  - jellyfish#v1.0.0:
      webhook-url: "https://webhooks.jellyfish.co/deployment"
      api-token: "${JELLYFISH_API_TOKEN}"
      name: "api-service-production"
      reference-id: "deploy-${BUILDKITE_BUILD_NUMBER}"
      labels:
        - "environment:production"
        - "service:api"
        - "version:${BUILDKITE_TAG}"
        - "region:us-east-1"
```

### Multiple Environment Deployments
```yaml
steps:
  - label: "Deploy to Staging"
    command: "./deploy.sh staging"
    plugins:
      - jellyfish#v1.0.0:
          webhook-url: "https://webhooks.jellyfish.co/deployment"
          api-token: "${JELLYFISH_API_TOKEN}"
          name: "staging-deployment"
          labels: ["environment:staging"]

  - wait

  - label: "Deploy to Production"
    command: "./deploy.sh production"
    plugins:
      - jellyfish#v1.0.0:
          webhook-url: "https://webhooks.jellyfish.co/deployment"
          api-token: "${JELLYFISH_API_TOKEN}"
          name: "production-deployment"
          labels: ["environment:production"]
```

## Testing

### Quick Test

Run the test runner to verify the plugin works:

```bash
./test.sh
```

### Test Options

```bash
./test.sh --quick      # Quick local test only
./test.sh --full       # Comprehensive test suite
./test.sh --payload    # JSON payload validation
./test.sh --all        # All tests (default)
```

This will simulate a Buildkite environment and test all functionality.

For detailed testing instructions, see [tests/README.md](tests/README.md).

## Troubleshooting

### Common Issues

1. **Plugin not triggering**: Ensure your build step exits with code 0 (success)
2. **Authentication errors**: Verify your API token is correct and has proper permissions
3. **Missing dependencies**: Ensure `curl` and `jq` are installed on your Buildkite agents
4. **Network issues**: Check that your agents can reach the Jellyfish webhook URL

### Debug Information

The plugin provides clear logging output:
- `🚀 Sending deployment webhook to Jellyfish...` - Plugin is starting
- `✅ Deployment webhook sent successfully to Jellyfish!` - Success
- `⚠️ Failed to send deployment webhook to Jellyfish...` - Error occurred

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with a real Buildkite pipeline
5. Submit a pull request

## License

This plugin is open source. See the repository for license details.

## Support

For issues related to:
- **Plugin functionality**: Open an issue in this repository
- **Jellyfish integration**: Contact Jellyfish support
- **Buildkite platform**: Refer to Buildkite documentation
