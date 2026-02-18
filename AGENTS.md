# AGENTS.md - Development & Deployment Guide

This project provides a standardized Docker environment for running an OpenClaw Gateway.

## Technical Context
- **Base Image**: `ghcr.io/astral-sh/uv:python3.14-bookworm-slim`
- **Runtime Environment**: Docker (standard or rootless).
- **Network**: Uses external networks `dokploy-network` and `cf-network` by default.
- **Port**: Gateway listens on port `18789`.

## Configuration Strategy (v2026 Schema)
The Gateway configuration is generated dynamically by `entrypoint.sh` using environment variables.

### Key Paths
- **Config File**: `/home/node/.openclaw/openclaw.json` (inside container)
- **Workspace**: `/home/node/.openclaw/workspace` (persisted via volume)
- **Binaries**: `/usr/bin/openclaw` (installed via npm global)

### Configuration Schema Mapping
When updating the configuration logic in `entrypoint.sh`:
- **Model**: Must be mapped to `agents.defaults.model.primary`.
- **OpenAI/LiteLLM**: Use `openai` or `openai-completions` as the API type.
- **Gemini**: Use `google-generative-ai` as the API type.
- **Browser**: Root-level `browser` object with `cdpUrl`.

## Build Process
The build is performed in the `volume_openclaw/` directory.
- `Dockerfile` handles system dependencies and the global npm installation of `openclaw`.
- `entrypoint.sh` handles startup logic, ulimit management, and dynamic JSON generation.

## Troubleshooting for Agents
- **EMFILE errors**: Check the `ulimit -n` inside the container or host.
- **Binary not found**: Ensure the `Dockerfile` correctly symlinks or adds the npm global bin path to the system `PATH`.
- **Invalid Config**: If OpenClaw fails with validation errors, ensure that all root keys are deleted after being moved to their new locations in the `v2026` schema.
