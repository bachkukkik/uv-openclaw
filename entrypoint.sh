#!/bin/sh
set -e

# 4. Configuration Script
node -e '
  const fs = require("fs");
  const path = "/home/node/.openclaw/openclaw.json";
  const token = process.env.OPENCLAW_GATEWAY_TOKEN;
  
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

  config.gateway = config.gateway || {};
  config.gateway.controlUi = config.gateway.controlUi || {};
  config.gateway.controlUi.allowInsecureAuth = true;
  config.gateway.trustedProxies = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.1/32"];
  config.gateway.auth = { mode: "token", token: token };
  
  fs.writeFileSync(path, JSON.stringify(config, null, 2));
'

# 5. Start Gateway
exec openclaw gateway --bind lan --port 18789 --allow-unconfigured
