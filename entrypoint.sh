#!/bin/sh
set -e

# Ensure directory exists
mkdir -p /home/node/.openclaw

# 4. Configuration Script - Mapping all environment variables to openclaw.json
# Updated for v2026.2.17 schema based on error feedback
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

  // New v2026 Schema: Providers and Tools are now under "agents" or "defaults"
  // According to error: "providers" is unrecognized at root. 
  // And "tools.browser" is unrecognized.
  
  config.agents = config.agents || {};
  config.agents.defaults = config.agents.defaults || {};
  
  // Try moving providers into agents.defaults or similar
  // Let\''s use the pattern where providers are defined per agent or globally in agents.
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
  // If tools.browser is unrecognized, maybe it\''s just tools.browserless or under agents?
  config.agents.tools = config.agents.tools || {};
  if (env.BROWSERLESS_BASE_URL) {
    config.agents.tools.browserless = {
      url: env.BROWSERLESS_BASE_URL,
      token: env.BROWSERLESS_TOKEN || undefined
    };
  }

  config.agents.defaults.model = config.agents.defaults.model || {};
  if (env.OPENAI_MODEL) {
    config.agents.defaults.model.primary = env.OPENAI_MODEL;
  } else if (env.GEMINI_API_KEY) {
    config.agents.defaults.model.primary = "google/gemini-3-pro-preview";
  }

  // Final Cleanup of legacy keys
  delete config.agent;
  delete config.providers;
  delete config.tools;

  fs.writeFileSync(path, JSON.stringify(config, null, 2));
  console.log("OpenClaw configuration updated successfully.");
'

# 5. Start Gateway
export HOME=/home/node
cd /home/node

# Explicitly add installer paths
export PATH="/root/.openclaw/bin:/home/node/.openclaw/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Binary detection
OPENCLAW_BIN=$(command -v openclaw || find /root/.openclaw/bin /home/node/.openclaw/bin /usr/local/bin /usr/bin -name openclaw -type f -executable | head -n 1)

if [ -z "$OPENCLAW_BIN" ]; then
    echo "Error: openclaw binary not found."
    exit 1
fi

echo "Attempting to auto-fix config with openclaw doctor..."
"$OPENCLAW_BIN" doctor --fix || true

echo "Starting OpenClaw gateway from: $OPENCLAW_BIN"
exec "$OPENCLAW_BIN" gateway --bind lan --port 18789 --allow-unconfigured
