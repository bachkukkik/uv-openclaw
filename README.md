# OpenClaw Gateway (UV-Enabled)

A high-performance, containerized OpenClaw Gateway environment optimized for agentic development, CI/CD, and Docker-in-Docker operations.

## Goals & Promises

- **Agentic Power**: Pre-configured with `gh` CLI and `uv` to enable agents to perform complex CI/CD and Python development tasks out of the box.
- **Docker-in-Docker (DooD)**: Built to manage sibling containers. Designed specifically for development workflows where the agent needs to build or inspect Docker-based repositories.
- **Zero-Config Startup**: Automatically generates a compliant `v2026` OpenClaw configuration from environment variables via a smart entrypoint script.
- **Security & Efficiency**: Uses `uv` for lightning-fast Python package management and implements file descriptor optimizations to prevent common gateway bottlenecks.
- **Clean Repo Policy**: Maintains a strict `llms_txt` policy to keep documentation in sync without cluttering the git history.

## Included Tools

| Tool | Purpose |
| ------ | --------- |
| **OpenClaw Gateway** | Core agentic bridge. |
| **UV** | High-performance Python package installer and resolver. |
| **GH CLI** | GitHub's official command-line tool for agentic CI/CD. |
| **Docker CLI** | For managing Docker environments (DooD mode). |
| **Node.js** | Runtime for OpenClaw and custom scripts. |
| **Opencode** | Specialized AI agent for code modification and repository analysis. |

## Quick Start (Dokploy / Docker Compose)

1. Set your `OPENCLAW_GATEWAY_TOKEN`.
2. Ensure `/var/run/docker.sock` is mounted for DooD support.
3. Deploy.

```yaml
services:
  openclaw-gateway:
    image: uv-openclaw
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - openclaw_config:/home/node/.openclaw
    environment:
      - OPENCLAW_GATEWAY_TOKEN=your_secure_token
```

## Environment Variables

| Variable | Description | Default |
| ---------- | ------------- | --------- |
| `OPENCLAW_GATEWAY_TOKEN` | Token for Gateway authentication | (Required) |
| `DEFAULT_MODEL_PROVIDER` | Provider for the primary agent model | `openai` |
| `OPENAI_DEFAULT_MODEL` | ID of the primary agent model | `openai/gpt-4o` |
| `OPENAI_API_KEY` | API Key for OpenAI or LiteLLM | - |
| `OPENAI_API_BASE` | Base URL for the OpenAI provider | `https://api.openai.com/v1` |
| `GEMINI_API_KEY` | API Key for Google Gemini | - |
| `BROWSERLESS_BASE_URL` | WebSocket URL for Browserless | - |
| `OPENCLAW_REQUIRE_CONTROL_UI_PAIRING` | Set to `false` to bypass pairing (Security Risk) | `true` |

## Troubleshooting: Pairing Required (1008)

If you see the error `disconnected (1008): pairing required` in the Control UI, it means the Gateway is asking for a one-time device approval.

### Option 1: Manual Approval (Recommended)

1. List pending pairing requests:

   ```bash
   docker exec -it openclaw-gateway openclaw devices list
   ```

2. Approve the request by its ID:

   ```bash
   docker exec -it openclaw-gateway openclaw devices approve <requestId>
   ```

### Option 2: Bypass Pairing (Trusted Networks Only)

If you are running in a private, trusted environment and want to disable the pairing requirement, set this variable to `false`:

```yaml
environment:
  - OPENCLAW_REQUIRE_CONTROL_UI_PAIRING=false
```

> [!WARNING]
> This is a security downgrade. Only use it in trusted environments.

## Project Structure

- `volume_openclaw/`: Contains the `Dockerfile` and `entrypoint.sh` for the build.
- `docker-compose.yml`: Main deployment configuration.
- `AGENTS.md`: Development & deployment guide for AI agents.
- `TESTING.md`: Test cases and system check results.
