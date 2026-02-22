#!/bin/sh
set -e

# Increase file descriptor limit to mitigate EMFILE errors if possible
ulimit -n 65535 2>/dev/null || true

# Ensure directory structure exists
mkdir -p /home/node/.openclaw/agents/main/sessions
mkdir -p /home/node/.openclaw/credentials

# 4. Configuration Script - Mapping environment variables to openclaw.json
node -e '
  const fs = require("fs");
  const path = "/home/node/.openclaw/openclaw.json";
  const env = process.env;

  const pairingRequired = env.OPENCLAW_REQUIRE_CONTROL_UI_PAIRING !== "false";
  const isBypassEnabled = !pairingRequired;
  const shouldOverride = env.OPENCLAW_OVERRIDE_CONFIG === "true" || isBypassEnabled;

  if (fs.existsSync(path) && !shouldOverride) {
    console.log("OpenClaw configuration already exists. Skipping initialization.");
    process.exit(0);
  }
  
  const token = env.OPENCLAW_GATEWAY_TOKEN;
  if (!token) {
    console.error("OPENCLAW_GATEWAY_TOKEN is not set.");
    process.exit(1);
  }

  const defaultModel = env.OPENAI_DEFAULT_MODEL || "gpt-4o";
  const defaultProvider = env.DEFAULT_MODEL_PROVIDER || "openai";

  let config = {
    commands: { native: "auto", nativeSkills: "auto" },
    gateway: {
      controlUi: { 
        allowInsecureAuth: true,
        dangerouslyDisableDeviceAuth: !pairingRequired
      },
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
    // Correct API type for LiteLLM/OpenAI-compatible providers
    const apiType = defaultProvider === "litellm" ? "openai-completions" : "openai";
    
    config.models.providers[defaultProvider] = {
      api: apiType,
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
      api: "google-generative-ai",
      apiKey: env.GEMINI_API_KEY,
      baseUrl: "https://generativelanguage.googleapis.com",
      models: []
    };
  }

  // Agents Configuration
  config.agents = {
    defaults: {
      model: { 
        primary: defaultProvider + "/" + defaultModel 
      }
    }
  };

  fs.writeFileSync(path, JSON.stringify(config, null, 2));
  console.log("OpenClaw configuration updated successfully (v2.3).");

  // 4.5 Opencode Fallback Setup
  const opencodeEnvPath = "/home/node/.env";
  const opencodeEnv = [
    `OPENAI_API_KEY=${env.OPENAI_API_KEY || ""}`,
    `OPENAI_API_BASE=${env.OPENAI_API_BASE || ""}`,
    `OPENAI_MODEL=${env.OPENAI_DEFAULT_MODEL || ""}`,
    `DEFAULT_MODEL=${env.OPENAI_DEFAULT_MODEL || ""}`
  ].join("\n");
  fs.writeFileSync(opencodeEnvPath, opencodeEnv);
  console.log("Opencode fallback environment initialized.");
'

# 5. Start Gateway
echo "Starting OpenClaw gateway..."

# Export fallbacks for opencode CLI
export OPENAI_MODEL="${OPENAI_DEFAULT_MODEL}"
export DEFAULT_MODEL="${OPENAI_DEFAULT_MODEL}"

exec openclaw gateway --bind lan --port 18789 --allow-unconfigured
