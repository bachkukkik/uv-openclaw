#!/bin/sh
set -e

# Increase file descriptor limit
ulimit -n 65535 2>/dev/null || true

# Ensure directory structure exists
mkdir -p /home/node/.openclaw
mkdir -p /home/node/.opencode

# Write dynamic openclaw.json if it doesn't exist or if override is enabled
if [ ! -f /home/node/.openclaw/openclaw.json ] || [ "${OPENCLAW_OVERRIDE_CONFIG}" = "true" ]; then
    echo "Updating OpenClaw gateway configuration..."
    cat <<EOF > /home/node/.openclaw/openclaw.json
{
  "messages": {
    "ackReactionScope": "group-mentions"
  },
  "models": {
    "mode": "merge",
    "providers": {
      "${DEFAULT_MODEL_PROVIDER}": {
        "baseUrl": "${OPENAI_API_BASE}",
        "apiKey": "${OPENAI_API_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "${OPENAI_DEFAULT_MODEL}",
            "name": "${OPENAI_DEFAULT_MODEL} (Custom Provider)",
            "reasoning": false,
            "input": ["text"],
            "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
            "contextWindow": ${OPENAI_DEFAULT_MODEL_CONTEXT_WINDOW:-262144},
            "maxTokens": ${OPENAI_DEFAULT_MODEL_MAX_TOKENS:-8192}
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "maxConcurrent": 4,
      "subagents": {
        "maxConcurrent": 8
      },
      "compaction": {
        "mode": "safeguard"
      },
      "workspace": "/home/node/.openclaw/workspace",
      "model": {
        "primary": "${DEFAULT_MODEL_PROVIDER}/${OPENAI_DEFAULT_MODEL}"
      },
      "models": {
        "openai/gpt-4o": {},
        "${DEFAULT_MODEL_PROVIDER}/${OPENAI_DEFAULT_MODEL}": {
          "alias": "primary-model"
        }
      }
    }
  },
  "gateway": {
    "mode": "local",
    "auth": {
      "mode": "token",
      "token": "${OPENCLAW_GATEWAY_TOKEN}"
    },
    "port": ${OPENCLAW_GATEWAY_PORT},
    "bind": "${OPENCLAW_GATEWAY_BIND}",
    "controlUi": {
      "enabled": true,
      "allowInsecureAuth": ${OPENCLAW_GATEWAY_ALLOW_INSECURE_AUTH},
      "dangerouslyDisableDeviceAuth": ${OPENCLAW_GATEWAY_DANGEROUSLY_DISABLE_DEVICE_AUTH}
    },
    "tailscale": {
      "mode": "off",
      "resetOnExit": false
    }
  },
  "skills": {
    "install": {
      "nodeManager": "npm"
    }
  },
  "browser": {
    "cdpUrl": "${BROWSERLESS_BASE_URL}"
  }
}
EOF
else
    echo "Using existing OpenClaw gateway configuration (OPENCLAW_OVERRIDE_CONFIG is not true)."
fi

echo "Starting OpenClaw gateway with manual-aligned config..."
exec openclaw gateway run
