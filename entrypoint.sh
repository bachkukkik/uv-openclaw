#!/bin/sh
set -e

# Ensure directory exists
mkdir -p /home/node/.openclaw

# 4. Configuration Script - Mapping all environment variables to openclaw.json
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

  // Providers Setup
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

  // Tools Setup (Browserless)
  if (env.BROWSERLESS_BASE_URL) {
    config.tools = config.tools || {};
    config.tools.browser = config.tools.browser || {};
    config.tools.browser.browserless = {
      url: env.BROWSERLESS_BASE_URL,
      token: env.BROWSERLESS_TOKEN || undefined
    };
  }

  // Agents Setup (New v2026 Schema)
  config.agents = config.agents || {};
  config.agents.defaults = config.agents.defaults || {};
  config.agents.defaults.model = config.agents.defaults.model || {};
  
  if (env.OPENAI_MODEL) {
    config.agents.defaults.model.primary = env.OPENAI_MODEL;
  } else if (env.GEMINI_API_KEY) {
    config.agents.defaults.model.primary = "google/gemini-3-pro-preview";
  }

  // Clean up legacy keys
  delete config.agent;

  fs.writeFileSync(path, JSON.stringify(config, null, 2));
  console.log("OpenClaw configuration updated successfully.");
'

# 5. Start Gateway
export HOME=/home/node
cd /home/node

echo "Searching for OpenClaw entry point..."

# Find the global node_modules path
NPM_ROOT=$(npm root -g)
PACKAGE_DIR="$NPM_ROOT/openclaw"

# Try different entry points
for f in "$PACKAGE_DIR/index.js" "$PACKAGE_DIR/dist/entry.js" "$PACKAGE_DIR/bin/openclaw"; do
    if [ -f "$f" ]; then
        echo "Starting OpenClaw via node: $f"
        exec node "$f" gateway --bind lan --port 18789 --allow-unconfigured
    fi
done

# Try calling it directly as a last resort
if command -v openclaw >/dev/null 2>&1; then
    echo "Starting OpenClaw gateway from binary path..."
    exec openclaw gateway --bind lan --port 18789 --allow-unconfigured
fi

echo "Error: Could not find OpenClaw entry point in $PACKAGE_DIR"
ls -R "$PACKAGE_DIR" 2>/dev/null || echo "Package directory not found."
exit 1
