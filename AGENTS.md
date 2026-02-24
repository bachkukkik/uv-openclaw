# AGENTS.md - Development & Deployment Guide

This project provides a standardized Docker environment for running an OpenClaw Gateway.

## Technical Context

- **Base Image**: `ghcr.io/astral-sh/uv:python:3.14-slim`
- **Runtime Environment**: Docker (standard or rootless).
- **Network**: Uses external network `${CF_NETWORK}` by default.
- **Port**: Gateway listens on port `18789` (Internal).
- **Access**: Accessed via proxy (e.g. Traefik) or internal network. Host port bindings removed.

## Configuration Strategy (v2026 Schema)

The Gateway configuration is generated dynamically by `entrypoint.sh` using environment variables.

### Key Paths

- **Config File**: `/home/node/.openclaw/openclaw.json` (inside container)
- **Workspace**: `/home/node/.openclaw/workspace` (persisted via volume)
- **Binaries**: `/usr/bin/openclaw` (installed via npm global)

### Configuration Schema Mapping

The configuration is strictly environment-driven. `entrypoint.sh` maps variables to their relevant JSON paths:

- `OPENAI_DEFAULT_MODEL` -> `agents.defaults.model.primary` and `agents.defaults.models` key.
- `OPENAI_API_KEY`/`OPENAI_API_BASE` -> `agents.defaults.models` details and fallback `.env` for Opencode/OpenSpec.
- `BROWSERLESS_BASE_URL`/`TOKEN` -> `skills.config.browserless`.
- `OPENCLAW_GATEWAY_*` -> `gateway` root settings.

## Build Process

The build is performed in the `volume_openclaw/` directory.

- `Dockerfile` handles system dependencies and the global npm installation of `openclaw`.
- `entrypoint.sh` handles startup logic, ulimit management, and dynamic JSON generation.

## Troubleshooting for Agents

- **EMFILE errors**: Check the `ulimit -n` inside the container or host.
- **Binary not found**: Ensure the `Dockerfile` correctly symlinks or adds the npm global bin path to the system `PATH`.
- **Invalid Config**: If OpenClaw fails with validation errors, ensure that all root keys are deleted after being moved to their new locations in the `v2026` schema.
