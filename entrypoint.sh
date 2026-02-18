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

  // Agent Defaults
  config.agent = config.agent || {};
  if (env.OPENAI_MODEL) {
    config.agent.model = env.OPENAI_MODEL;
  }

  fs.writeFileSync(path, JSON.stringify(config, null, 2));
  console.log("OpenClaw configuration updated successfully.");
'

# 5. Start Gateway
export HOME=/home/node
cd /home/node

# Robust binary detection
echo "Searching for openclaw binary..."
OPENCLAW_BIN=""

if command -v openclaw >/dev/null 2>&1; then
    OPENCLAW_BIN=$(command -v openclaw)
else
    # Try common npm global locations
    for p in /usr/local/bin/openclaw /usr/bin/openclaw /opt/node/bin/openclaw; do
        if [ -x "$p" ]; then
            OPENCLAW_BIN="$p"
            break
        fi
    done
fi

# Final fallback: use npx if installed
if [ -z "$OPENCLAW_BIN" ]; then
    if command -v npx >/dev/null 2>&1; then
        echo "Binary not found in PATH, using npx fallback..."
        exec npx openclaw gateway --bind lan --port 18789 --allow-unconfigured
    else
        echo "Error: openclaw binary not found and npx is missing."
        exit 1
    fi
fi

echo "Starting OpenClaw gateway from: $OPENCLAW_BIN"
exec "$OPENCLAW_BIN" gateway --bind lan --port 18789 --allow-unconfigured
