#!/bin/bash
echo "--- OpenClaw Gateway Diagnostic ---"
echo "Date: $(date)"
echo "User: $(whoami)"

echo -e "\n1. Checking Environment Variables (Redacted):"
env | grep OPENCLAW | sed 's/TOKEN=.*/TOKEN=[REDACTED]/g'

echo -e "\n2. Checking openclaw.json state:"
if [ -f /home/node/.openclaw/openclaw.json ]; then
    echo "Config file exists at /home/node/.openclaw/openclaw.json"
    # Filter for interesting keys only
    grep -E "dangerouslyDisableDeviceAuth|trustedProxies|auth" /home/node/.openclaw/openclaw.json | sed 's/"token": "[^"]*"/"token": "[REDACTED]"/g'
else
    echo "ERROR: Config file NOT FOUND at /home/node/.openclaw/openclaw.json"
fi

echo -e "\n3. Checking Network (Headers/IPs):"
# This might help see if it thinks it's behind a proxy
ip addr show | grep inet

echo -e "\n4. Recent Gateway Logs (Last 10 lines):"
ls -t /tmp/openclaw/openclaw-*.log 2>/dev/null | head -n 1 | xargs tail -n 10 2>/dev/null || echo "No log files found in /tmp/openclaw/"
