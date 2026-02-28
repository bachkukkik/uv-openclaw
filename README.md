# OpenClaw Gateway (UV-Enabled)

A high-performance, containerized OpenClaw Gateway environment optimized for agentic development, CI/CD, and Docker-in-Docker operations.

## Goals & Promises

- **Agentic Power**: Pre-configured with `gh` CLI and `uv` to enable agents to perform complex CI/CD and Python development tasks out of the box.
- **Docker-in-Docker (DooD)**: Built to manage sibling containers. Designed specifically for development workflows where the agent needs to build or inspect Docker-based repositories.
- **Zero-Config Plugin Suite**: Automatically installs and configures `opencode-antigravity-auth` and `opencode-plugin-openspec` for immediate use.
- **Security & Efficiency**: Uses `uv` and `bun` for lightning-fast package management and implements file descriptor optimizations.
- **Clean Repo Policy**: Maintains a strict `llms_txt` policy to keep documentation in sync without cluttering the git history.

## Included Tools

| Tool | Purpose |
| ------ | --------- |
| **OpenClaw Gateway** | Core agentic bridge. |
| **UV** | High-performance Python package installer and resolver. |
| **GH CLI** | GitHub's official command-line tool for agentic CI/CD. |
| **Docker CLI** | For managing Docker environments (DooD mode). |
| **Node.js & Bun** | Runtimes for OpenClaw, Opencode, and high-performance JS tasks. |
| **Opencode Plugins** | Pre-configured with **Antigravity Auth** (OAuth2) and **OpenSpec Architect**. |
| **OpenSpec (OPSX)** | Specification-driven agentic workflow tool for structured development. |

## Quick Start (Dokploy / Docker Compose)

1. Set your `OPENCLAW_GATEWAY_TOKEN`.
2. Ensure `/var/run/docker.sock` is mounted for DooD support.
3. Deploy.

```yaml
services:
  openclaw-gateway:
    image: ghcr.io/bachkukkik/uv-openclaw:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - openclaw_config:/home/node/.openclaw
    environment:
      - OPENCLAW_GATEWAY_TOKEN=your_secure_token_here
```

## Environment Variables

| Variable | Description | Default |
| ---------- | ------------- | --------- |
| `OPENCLAW_GATEWAY_TOKEN` | Token for Gateway authentication | (Required) |
| `OPENCLAW_GATEWAY_PORT` | Internal port for the Gateway | `18789` |
| `OPENCLAW_GATEWAY_DANGEROUSLY_ALLOW_HOST_HEADER_ORIGIN_FALLBACK` | Allow Host-header origin fallback for non-loopback access | `true` |
| `OPENCLAW_OVERRIDE_CONFIG` | Overwrite `openclaw.json` on every start | `false` |
| `OPENCODE_OVERRIDE_CONFIG` | Overwrite `opencode.json` on every start | `false` |
| `DEFAULT_MODEL_PROVIDER` | Provider for the primary agent model | `openai` |
| `OPENAI_DEFAULT_MODEL` | ID of the primary agent model | `openai/gpt-4o` |
| `OPENAI_DEFAULT_MODEL_CONTEXT_WINDOW` | Default context window tokens | `262144` |
| `OPENAI_DEFAULT_MODEL_MAX_TOKENS` | Default max completion tokens | `8192` |
| `OPENAI_API_KEY` | API Key for OpenAI or LiteLLM | - |
| `OPENAI_BASE_URL` | Base URL for OpenAI/LiteLLM (used by OpenClaw & Opencode) | `https://api.openai.com/v1` |
| `GEMINI_API_KEY` | API Key for Google Gemini | - |
| `BROWSERLESS_BASE_URL` | WebSocket URL for Browserless | - |

> [!TIP]
> For a full list of all supported environment variables, see [ENV_VARS.md](file:///Users/bachkukkik/Archives/GitHub_Repo/sandbox/uv-openclaw/ENV_VARS.md).

## Resource Requirements

To handle skill configuration and heavy agent tasks, it is recommended to allocate at least **8GB of RAM** to the Docker daemon.

- **Minimum**: 4GB
- **Recommended**: 8GB+

## Troubleshooting

### Exit Code 137 (OOM / Conflict)

If you see **exit code 137** during `openclaw onboard`, it can be due to:

1. **Memory Spike**: Skill scanning is resource-intensive.
2. **Process Conflict**: The gateway is already running and configured.

**IMPORTANT**: Since this image is **Pre-Configured** via environment variables, you **do not need** to run `openclaw onboard`. Your gateway is already "nailed" and ready to use.

**Recommended Solution**:

- **Skip Onboarding**: Don't run `openclaw onboard`.
- **Verify Gateway**: Check logs inside the container: `docker logs <container>`
- **Use Dashboard**: Access the Control UI via your configured proxy URL.

### Pairing Required (1008)

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

If you are running in a private, trusted environment and want to disable the pairing requirement, set these variables to `true`:

```yaml
environment:
  - OPENCLAW_GATEWAY_ALLOW_INSECURE_AUTH=true
  - OPENCLAW_GATEWAY_DANGEROUSLY_DISABLE_DEVICE_AUTH=true
  - OPENCLAW_GATEWAY_DANGEROUSLY_ALLOW_HOST_HEADER_ORIGIN_FALLBACK=true
```

> [!WARNING]
> This is a security downgrade. Only use it in trusted environments.

## Project Structure

- `volume_openclaw/`: Contains the `Dockerfile` and `entrypoint.sh` for the build.
- `docker-compose.yml`: Main deployment configuration.
- `AGENTS.md`: Development & deployment guide for AI agents.
- `TESTING.md`: Test cases and system check results.
