#!/bin/sh
set -e

# Ensure directory structure exists
mkdir -p /home/node/.openclaw/agents/main/sessions
mkdir -p /home/node/.openclaw/credentials

# 4. Configuration Script - Mapping environment variables to openclaw.json
node -e '
  const fs = require("fs");
  const path = "/home/node/.openclaw/openclaw.json";
  const env = process.env;
  
  const token = env.OPENCLAW_GATEWAY_TOKEN;
  if (!token) {
    console.error("OPENCLAW_GATEWAY_TOKEN is not set.");
    process.exit(1);
  }

  const defaultModel = env.OPENAI_DEFAULT_MODEL || "openai/gpt-4o";

  let config = {
    commands: { native: "auto", nativeSkills: "auto" },
    gateway: {
      controlUi: { allowInsecureAuth: true },
      auth: { mode: "token", token: token },
      trustedProxies: ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.1/32"],
      port: 18789,
      mode: "local",
      bind: "lan"
    }
  };

  // Browser Configuration
  if (env.BROWSERLESS_BASE_URL) {
    const cdpUrl = env.BROWSERLESS_BASE_URL + (env.BROWSERLESS_TOKEN ? "?token=" + env.BROWSERLESS_TOKEN : "");
    config.browser = {
      enabled: true,
      cdpUrl: cdpUrl,
      color: "#00ffff",
      profiles: {
        openclaw: { cdpUrl: cdpUrl, color: "#00ffff" }
      }
    };
  }

  // Models and Providers
  config.models = { providers: {} };
  
  if (env.OPENAI_API_KEY) {
    config.models.providers.openai = {
      apiKey: env.OPENAI_API_KEY,
      baseUrl: env.OPENAI_API_BASE || "https://api.openai.com/v1",
      models: [
        {
          id: defaultModel,
          name: defaultModel,
          reasoning: false,
          input: ["text"],
          cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
          contextWindow: 262144,
          maxTokens: 262144
        }
      ]
    };
  }

  if (env.GEMINI_API_KEY) {
    config.models.providers.gemini = {
      apiKey: env.GEMINI_API_KEY,
      baseUrl: "https://generativelanguage.googleapis.com",
      models: []
    };
  }

  // Agents Configuration
  config.agents = {
    defaults: {
      model: { primary: defaultModel.includes("/") ? defaultModel : "openai/" + defaultModel }
    }
  };

  fs.writeFileSync(path, JSON.stringify(config, null, 2));
  console.log("OpenClaw configuration updated successfully (minimal).");
'

# 5. Start Gateway
export HOME=/home/node
cd /home/node

export PATH="/root/.openclaw/bin:/home/node/.openclaw/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
OPENCLAW_BIN=$(command -v openclaw || find /root/.openclaw/bin /home/node/.openclaw/bin /usr/local/bin -name openclaw -type f -executable | head -n 1)

echo "Starting OpenClaw gateway..."
exec "$OPENCLAW_BIN" gateway --bind lan --port 18789 --allow-unconfigured
