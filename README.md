# OpenClaw Docker Gateway

A standardized Docker deployment for the OpenClaw Gateway (v2026.2.17+).

## Features
- **Auto-Config**: Automatically maps environment variables to `openclaw.json` at startup.
- **Provider Support**: Ready-to-use configuration for OpenAI, LiteLLM, and Gemini.
- **Browser Control**: Integrated Browserless configuration.
- **Self-Healing**: Automatic creation of required directory structures.

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/bachkukkik/uv-openclaw.git
   cd uv-openclaw
   ```

2. **Configure your environment**:
   Copy `.env.example` to `.env` and fill in your keys:
   ```bash
   cp .env.example .env
   ```

3. **Deploy with Docker Compose**:
   ```bash
   docker compose up -d
   ```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENCLAW_GATEWAY_TOKEN` | Token for Gateway authentication | (Required) |
| `DEFAULT_MODEL_PROVIDER` | Provider for the primary agent model | `openai` |
| `OPENAI_DEFAULT_MODEL` | ID of the primary agent model | `openai/gpt-4o` |
| `OPENAI_API_KEY` | API Key for OpenAI or LiteLLM | - |
| `OPENAI_API_BASE` | Base URL for the OpenAI provider | `https://api.openai.com/v1` |
| `GEMINI_API_KEY` | API Key for Google Gemini | - |
| `BROWSERLESS_BASE_URL` | WebSocket URL for Browserless | - |

## Project Structure
- `volume_openclaw/`: Contains the `Dockerfile` and `entrypoint.sh` for the build.
- `docker-compose.yml`: Main deployment configuration.
- `.env.example`: Template for environment configuration.
