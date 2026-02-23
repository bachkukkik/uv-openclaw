# Environment Variables Reference

This document provides a comprehensive list of all environment variables supported by the UV-Enabled OpenClaw Gateway.

## Gateway configuration

| Variable | Description | Default |
| :--- | :--- | :--- |
| `PYTHON_IMAGE_TAG` | Docker image tag for the `uv` base. | `python:3.14-slim` |
| `OPENCLAW_GATEWAY_TOKEN` | Secret token for dashboard and API authentication. | **(Required)** |
| `OPENCLAW_GATEWAY_PORT` | Port the gateway listens on inside the container. | `18789` |
| `OPENCLAW_GATEWAY_BIND` | Network interface to bind (`loopback`, `lan`, `all`). | `lan` |
| `OPENCLAW_GATEWAY_ALLOW_INSECURE_AUTH` | Allow login over HTTP (non-HTTPS). | `true` |
| `OPENCLAW_GATEWAY_DANGEROUSLY_DISABLE_DEVICE_AUTH` | Disable one-time device pairing requirement. | `true` |
| `OPENCLAW_OVERRIDE_CONFIG` | If `true`, overwrites `openclaw.json` on every startup. | `false` |

## LLM Model configuration

These variables configure the primary model used by agents.

| Variable | Description | Default |
| :--- | :--- | :--- |
| `DEFAULT_MODEL_PROVIDER` | Name of the OpenAI-compatible provider (e.g. `litellm`). | `openai` |
| `OPENAI_DEFAULT_MODEL` | The model ID to use (e.g. `gpt-4o`). | `openai/gpt-4o` |
| `OPENAI_DEFAULT_MODEL_CONTEXT_WINDOW` | Maximum context tokens for the primary model. | `262144` |
| `OPENAI_DEFAULT_MODEL_MAX_TOKENS` | Maximum completion tokens for the primary model. | `8192` |
| `OPENAI_API_KEY` | API Key for the default provider. | - |
| `OPENAI_API_BASE` | Base URL for the default provider. | `https://api.openai.com/v1` |
| `GEMINI_API_KEY` | API Key for Google Gemini (optional). | - |

## Browser Control

| Variable | Description | Default |
| :--- | :--- | :--- |
| `BROWSERLESS_BASE_URL` | WebSocket URL for a Browserless instance. | - |
| `BROWSERLESS_TOKEN` | Authentication token for Browserless. | - |

## System internals

| Variable | Description | Default |
| :--- | :--- | :--- |
| `HOME` | Home directory inside the container. | `/home/node` |
| `TERM` | Terminal type for interactive shells. | `xterm-256color` |
| `NO_ONBOARD` | Disables the interactive onboarding wizard. | `1` |
| `OPENCLAW_NO_PROMPT` | Disables interactive prompts in the CLI. | `1` |
