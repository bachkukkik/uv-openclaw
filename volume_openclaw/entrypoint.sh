#!/bin/sh
set -e

# Increase file descriptor limit
ulimit -n 65535 2>/dev/null || true

# Ensure all tool paths are included in the environment
export PATH=$PATH:/root/.openclaw/bin:/home/node/.openclaw/bin:/root/.opencode/bin:/root/.openspec/bin:/root/.cargo/bin:/root/.local/bin

# Ensure directory structure exists
mkdir -p /home/node/.openclaw
mkdir -p /home/node/.openclaw/workspace
mkdir -p /home/node/.config/gh
mkdir -p /home/node/.config/opencode

# 1. Initialize or Reset configuration
if [ ! -f /home/node/.openclaw/openclaw.json ] || [ "${OPENCLAW_OVERRIDE_CONFIG}" = "true" ]; then
    echo "Writing full OpenClaw configuration..."
    
    # Use 18789 if port is not set
    OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"

    # Standardize Base URL and handle legacy fallbacks
    OPENAI_BASE_URL="${OPENAI_BASE_URL:-${OPENAI_API_BASE_URL:-${OPENAI_API_BASE}}}"
    
    # Provide a default for OpenAI if the provider is openai and no URL is set
    if [ "${DEFAULT_MODEL_PROVIDER}" = "openai" ] && [ -z "${OPENAI_BASE_URL}" ]; then
        OPENAI_BASE_URL="https://api.openai.com/v1"
    fi
    
    # We write the full JSON manually to bypass v2026 CLI hangs (142% CPU)
    # and to ensure a perfect meta-tagged config that satisfies the gateway.
    # The Antigravity extension is removed in the Dockerfile.
    
    # Construct cdpUrl with token if provided
    CDP_URL="${BROWSERLESS_BASE_URL}"
    if [ -n "${BROWSERLESS_TOKEN}" ]; then
        if echo "${CDP_URL}" | grep -q "?"; then
            CDP_URL="${CDP_URL}&token=${BROWSERLESS_TOKEN}"
        else
            CDP_URL="${CDP_URL}?token=${BROWSERLESS_TOKEN}"
        fi
    fi

    cat <<EOF > /home/node/.openclaw/openclaw.json
{
  "browser": {
    "cdpUrl": "${CDP_URL}"
  },
  "models": {
    "mode": "merge",
    "providers": {
      "${DEFAULT_MODEL_PROVIDER}": {
        "baseUrl": "${OPENAI_BASE_URL}",
        "apiKey": "${OPENAI_API_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "${OPENAI_DEFAULT_MODEL}",
            "name": "${OPENAI_DEFAULT_MODEL}",
            "contextWindow": ${OPENAI_DEFAULT_MODEL_CONTEXT_WINDOW:-262144},
            "maxTokens": ${OPENAI_DEFAULT_MODEL_MAX_TOKENS:-8192}
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "${DEFAULT_MODEL_PROVIDER}/${OPENAI_DEFAULT_MODEL}"
      },
      "models": {
        "${DEFAULT_MODEL_PROVIDER}/${OPENAI_DEFAULT_MODEL}": {
          "alias": "primary-model"
        }
      },
      "workspace": "/home/node/.openclaw/workspace"
    }
  },
    "gateway": {
      "port": ${OPENCLAW_GATEWAY_PORT},
      "mode": "local",
      "bind": "custom",
      "customBindHost": "0.0.0.0",
    "controlUi": {
      "allowInsecureAuth": ${OPENCLAW_GATEWAY_ALLOW_INSECURE_AUTH},
      "dangerouslyDisableDeviceAuth": ${OPENCLAW_GATEWAY_DANGEROUSLY_DISABLE_DEVICE_AUTH},
      "dangerouslyAllowHostHeaderOriginFallback": ${OPENCLAW_GATEWAY_DANGEROUSLY_ALLOW_HOST_HEADER_ORIGIN_FALLBACK:-true}
    },
    "trustedProxies": ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.1/32"],
    "auth": {
      "mode": "token",
      "token": "${OPENCLAW_GATEWAY_TOKEN}"
    }
  }
}
EOF
    echo "Configuration written manually with metadata."
else
    echo "Using existing OpenClaw configuration."
fi

# Ensure Opencode is also configured (fallback)
if [ ! -f /home/node/.env ]; then
    echo "Generating Opencode fallback .env..."
    cat <<EOF > /home/node/.env
OPENAI_API_KEY=${OPENAI_API_KEY}
OPENAI_BASE_URL=${OPENAI_BASE_URL}
OPENAI_MODEL=${OPENAI_DEFAULT_MODEL}
EOF
fi

# 2. Configure Opencode Global Config
if [ ! -f /home/node/.config/opencode/opencode.json ] || [ "${OPENCODE_OVERRIDE_CONFIG}" = "true" ]; then
    echo "Writing global Opencode configuration..."
    
    cat <<EOF > /home/node/.config/opencode/opencode.json
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "$DEFAULT_MODEL_PROVIDER/$OPENAI_DEFAULT_MODEL",
  "plugin": [
    "opencode-antigravity-auth@latest",
    "opencode-plugin-openspec"
  ],
  "provider": {
    "$DEFAULT_MODEL_PROVIDER": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "$DEFAULT_MODEL_PROVIDER",
      "options": {
        "baseURL": "$OPENAI_BASE_URL",
        "apiKey": "$OPENAI_API_KEY"
      },
      "models": {
        "$OPENAI_DEFAULT_MODEL": {
          "name": "$OPENAI_DEFAULT_MODEL"
        }
      }
    }
  }
}
EOF
    echo "Global Opencode configuration written."
fi

echo "Starting OpenClaw gateway in non-interactive mode..."
export OPENCLAW_GATEWAY_NO_ONBOARD=1
export OPENCLAW_GATEWAY_NO_PROMPT=1
export CI=true

# Final safety: use redirection to close any zombie prompts
# Use flags for token, port, and bind to reduce reliance on JSON if needed
exec openclaw gateway run \
    --token "${OPENCLAW_GATEWAY_TOKEN}" \
    --port "${OPENCLAW_GATEWAY_PORT}" \
    --bind "custom" < /dev/null

