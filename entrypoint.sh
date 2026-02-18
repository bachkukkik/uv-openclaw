#!/bin/sh
set -e

# Ensure directory exists
mkdir -p /home/node/.openclaw

# 4. Configuration Script - Mapping environment variables to openclaw.json
# Strictly following v2026.2.17 schema requirements
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

  // 1. Gateway Configuration
  config.gateway = config.gateway || {};
  config.gateway.port = 18789;
  config.gateway.mode = "local";
  config.gateway.bind = "lan";
  config.gateway.controlUi = config.gateway.controlUi || {};
  config.gateway.controlUi.allowInsecureAuth = true;
  config.gateway.trustedProxies = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.1/32"];
  config.gateway.auth = { mode: "token", token: token };

  // 2. Browser Configuration
  if (env.BROWSERLESS_BASE_URL) {
    const cdpUrl = env.BROWSERLESS_BASE_URL + (env.BROWSERLESS_TOKEN ? "?token=" + env.BROWSERLESS_TOKEN : "");
    config.browser = {
      enabled: true,
      cdpUrl: cdpUrl,
      color: "#00ffff",
      profiles: {
        openclaw: {
          cdpUrl: cdpUrl,
          color: "#00ffff"
        }
      }
    };
  }

  // 3. Models Configuration
  config.models = config.models || {};
  config.models.providers = config.models.providers || {};
  
  if (env.OPENAI_API_KEY) {
    config.models.providers.openai = {
      apiKey: env.OPENAI_API_KEY,
      baseUrl: env.OPENAI_API_BASE || "https://api.openai.com/v1",
      models: [] // Required by schema
    };
  }

  if (env.GEMINI_API_KEY) {
    config.models.providers.gemini = {
      apiKey: env.GEMINI_API_KEY,
      baseUrl: "https://generativelanguage.googleapis.com", // Required by schema
      models: [] // Required by schema
    };
  }

  // 4. Agents Configuration
  config.agents = config.agents || {};
  config.agents.defaults = config.agents.defaults || {};
  config.agents.defaults.model = config.agents.defaults.model || {};
  
  if (env.OPENAI_MODEL) {
    config.agents.defaults.model.primary = env.OPENAI_MODEL;
  }

  // Clean legacy keys
  delete config.agent;
  delete config.providers;
  delete config.tools;

  fs.writeFileSync(path, JSON.stringify(config, null, 2));
  console.log("OpenClaw configuration hardened for v2026.2.17.");
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

echo "Starting OpenClaw gateway..."
exec "$OPENCLAW_BIN" gateway --bind lan --port 18789 --allow-unconfigured
