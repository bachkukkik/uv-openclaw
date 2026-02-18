#!/bin/sh
set -e

# Ensure directory exists
mkdir -p /home/node/.openclaw

# 4. Configuration Script - Mapping environment variables to openclaw.json
# Using a "Seed and Heal" strategy for v2026.2.17 schema
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
    } catch (e) {}
  }

  // Gateway Setup (Stable)
  config.gateway = config.gateway || {};
  config.gateway.controlUi = config.gateway.controlUi || {};
  config.gateway.controlUi.allowInsecureAuth = true;
  config.gateway.trustedProxies = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.1/32"];
  config.gateway.auth = { mode: "token", token: token };

  // Seed with legacy structure to trigger OpenClaw\''s built-in auto-migration
  // This is the most reliable way to handle schema changes between versions
  config.agent = config.agent || {};
  if (env.OPENAI_MODEL) {
    config.agent.model = env.OPENAI_MODEL;
  } else if (env.GEMINI_API_KEY) {
    config.agent.model = "google/gemini-3-pro-preview";
  }

  config.providers = config.providers || {};
  if (env.OPENAI_API_KEY) {
    config.providers.openai = {
      apiKey: env.OPENAI_API_KEY,
      baseUrl: env.OPENAI_API_BASE || undefined
    };
  }
  if (env.GEMINI_API_KEY) {
    config.providers.gemini = {
      apiKey: env.GEMINI_API_KEY
    };
  }

  config.tools = config.tools || {};
  if (env.BROWSERLESS_BASE_URL) {
    config.tools.browser = {
      browserless: {
        url: env.BROWSERLESS_BASE_URL,
        token: env.BROWSERLESS_TOKEN || undefined
      }
    };
  }

  // Remove the new keys we tried earlier to start clean for the doctor
  delete config.agents;

  fs.writeFileSync(path, JSON.stringify(config, null, 2));
  console.log("OpenClaw seed configuration written.");
'

# 5. Start Gateway
export HOME=/home/node
cd /home/node

# Standard path
export PATH="/root/.openclaw/bin:/home/node/.openclaw/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Binary detection
OPENCLAW_BIN=$(command -v openclaw || find /root/.openclaw/bin /home/node/.openclaw/bin /usr/local/bin -name openclaw -type f -executable | head -n 1)

if [ -z "$OPENCLAW_BIN" ]; then
    echo "Error: openclaw binary not found."
    exit 1
fi

# Use OpenClaw\''s own migration engine to fix the config to the current version
echo "Running openclaw doctor to migrate configuration..."
"$OPENCLAW_BIN" doctor --fix || true

echo "Fixed configuration:"
cat /home/node/.openclaw/openclaw.json

echo "Starting OpenClaw gateway..."
exec "$OPENCLAW_BIN" gateway --bind lan --port 18789 --allow-unconfigured
