#!/bin/sh
set -e

# Ensure directory exists
mkdir -p /home/node/.openclaw

# 4. Configuration Script
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
      console.warn("Could not parse existing config, starting fresh.");
    }
  }

  // Gateway Setup
  config.gateway = config.gateway || {};
  config.gateway.controlUi = config.gateway.controlUi || {};
  config.gateway.controlUi.allowInsecureAuth = true;
  config.gateway.trustedProxies = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.1/32"];
  config.gateway.auth = { mode: "token", token: token };

  // Providers Setup
  config.providers = config.providers || {};
  
  if (env.OPENAI_API_KEY) {
    config.providers.openai = {
      apiKey: env.OPENAI_API_KEY,
      baseUrl: env.OPENAI_API_BASE || undefined,
      model: env.OPENAI_MODEL || "openai/gpt-4o"
    };
  }

  if (env.GEMINI_API_KEY) {
    config.providers.gemini = {
      apiKey: env.GEMINI_API_KEY
    };
  }

  // Tools Setup (Browserless)
  if (env.BROWSERLESS_BASE_URL) {
    config.tools = config.tools || {};
    config.tools.browser = config.tools.browser || {};
    config.tools.browser.browserless = {
      url: env.BROWSERLESS_BASE_URL,
      token: env.BROWSERLESS_TOKEN || undefined
    };
  }

  // Identity/Defaults (Make it well-equipped)
  config.agent = config.agent || {};
  if (env.OPENAI_MODEL) {
    config.agent.model = env.OPENAI_MODEL;
  } else if (env.GEMINI_API_KEY) {
    config.agent.model = "google/gemini-3-pro-preview";
  }

  fs.writeFileSync(path, JSON.stringify(config, null, 2));
  console.log("OpenClaw configuration updated successfully.");
'

# 5. Start Gateway
export HOME=/home/node
cd /home/node

# Debug information
echo "Current User: $(whoami)"
echo "PATH: $PATH"
echo "NPM Global Bin: $(npm config get prefix)/bin"
ls -l "$(npm config get prefix)/bin/openclaw" 2>/dev/null || echo "OpenClaw not found in npm global bin"

# Try to find the binary with multiple fallbacks
if command -v openclaw >/dev/null 2>&1; then
    OPENCLAW_BIN=$(command -v openclaw)
elif [ -f "$(npm config get prefix)/bin/openclaw" ]; then
    OPENCLAW_BIN="$(npm config get prefix)/bin/openclaw"
else
    # Last resort: try npx (it might be slow but it works)
    echo "Using npx as fallback..."
    exec npx openclaw gateway --bind lan --port 18789 --allow-unconfigured
fi

echo "Starting OpenClaw from: $OPENCLAW_BIN"
exec "$OPENCLAW_BIN" gateway --bind lan --port 18789 --allow-unconfigured
