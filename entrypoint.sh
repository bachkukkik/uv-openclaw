#!/bin/sh
set -e

# Ensure directory exists
mkdir -p /home/node/.openclaw

# 4. Configuration Script - Mapping environment variables to openclaw.json
# Updated for v2026.2.17 schema
node -e '
  const fs = require("fs");
  const path = "/home/node/.openclaw/openclaw.json";
  const env = process.env;
  
  const token = env.OPENCLAW_GATEWAY_TOKEN;
  if (!token) {
    console.error("OPENCLAW_GATEWAY_TOKEN is not set.");
    process.exit(1);
  }

  let config = {};
  if (fs.existsSync(path)) {
    try {
      config = JSON.parse(fs.readFileSync(path, "utf8"));
    } catch (e) {
      console.warn("Starting with fresh config.");
    }
  }

  // Gateway Setup
  config.gateway = config.gateway || {};
  config.gateway.controlUi = config.gateway.controlUi || {};
  config.gateway.controlUi.allowInsecureAuth = true;
  config.gateway.trustedProxies = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.1/32"];
  config.gateway.auth = { mode: "token", token: token };

  // Agents and Defaults (v2026 schema)
  config.agents = config.agents || {};
  config.agents.defaults = config.agents.defaults || {};
  config.agents.defaults.model = config.agents.defaults.model || {};

  // Map LLM settings
  if (env.OPENAI_API_KEY) {
    config.agents.defaults.model.primary = env.OPENAI_MODEL || "openai/gpt-4o";
  } else if (env.GEMINI_API_KEY) {
    config.agents.defaults.model.primary = "google/gemini-3-pro-preview";
  }

  // Providers Setup
  config.agents.providers = config.agents.providers || {};
  if (env.OPENAI_API_KEY) {
    config.agents.providers.openai = {
      apiKey: env.OPENAI_API_KEY,
      baseUrl: env.OPENAI_API_BASE || undefined
    };
  }
  if (env.GEMINI_API_KEY) {
    config.agents.providers.gemini = {
      apiKey: env.GEMINI_API_KEY
    };
  }

  // Tools Setup (Browserless)
  config.agents.tools = config.agents.tools || {};
  if (env.BROWSERLESS_BASE_URL) {
    config.agents.tools.browserless = {
      url: env.BROWSERLESS_BASE_URL,
      token: env.BROWSERLESS_TOKEN || undefined
    };
  }

  // Clean legacy keys
  delete config.agent;
  delete config.providers;
  delete config.tools;

  fs.writeFileSync(path, JSON.stringify(config, null, 2));
  console.log("OpenClaw configuration updated successfully.");
'

# 5. Start Gateway
export HOME=/home/node
cd /home/node

# Standard path
export PATH="/root/.openclaw/bin:/home/node/.openclaw/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Binary detection
echo "Searching for OpenClaw binary..."
OPENCLAW_BIN=$(command -v openclaw || find /root/.openclaw/bin /home/node/.openclaw/bin /usr/local/bin -name openclaw -type f -executable | head -n 1)

if [ -z "$OPENCLAW_BIN" ]; then
    echo "Emergency: OpenClaw not found. Attempting runtime install..."
    export NO_ONBOARD=1
    export OPENCLAW_NO_PROMPT=1
    curl -fsSL https://openclaw.ai/install.sh | bash || true
    OPENCLAW_BIN=$(find /root/.openclaw/bin /home/node/.openclaw/bin -name openclaw -type f -executable | head -n 1)
fi

if [ -z "$OPENCLAW_BIN" ]; then
    echo "Error: Failed to find or install OpenClaw."
    exit 1
fi

echo "Starting OpenClaw gateway from: $OPENCLAW_BIN"
exec "$OPENCLAW_BIN" gateway --bind lan --port 18789 --allow-unconfigured
