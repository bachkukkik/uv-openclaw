# Testing & Deployment Verification

This document summarizes the test cases conducted to verify the repository upgrade and provides a manual test case for deployment verification.

## Test Results (Sun Feb 22 2026)

| Test Case | Description | Result |
|-----------|-------------|--------|
| **Environment Check** | Verify `uv`, `gh`, `node`, and `openclaw` are installed in the image. | **PASS** |
| **DooD Verification** | Verify `docker` CLI and socket access inside the container. | **PASS** |
| **Config Generation** | Verify `entrypoint.sh` generates `openclaw.json` using the v2026 schema. | **PASS** |
| **Git Protection** | Verify `llms_txt/*` is ignored by Git, excluding `.gitkeep`. | **PASS** |

## Full System Check (Automated) - Sun Feb 22 2026

I performed a full system check by building the container and executing verification commands internally.

| Component | Status | Verification Command |
|-----------|--------|----------------------|
| **Python Tooling** | **PASS** | `uv --version` (v0.9.30) |
| **GitHub CLI** | **PASS** | `gh --version` (v2.87.2) |
| **Docker CLI** | **PASS** | `docker --version` (v29.2.1) |
| **Docker Compose** | **PASS** | `docker compose version` (v5.0.2) |
| **Node.js** | **PASS** | `node --version` (v22.22.0) |
| **OpenClaw** | **PASS** | `openclaw --version` (2026.2.21-2) |
| **Opencode** | **PASS** | `opencode --version` (v1.0.5) |
| **Git Rules** | **PASS** | `git check-ignore` (llms_txt/* blocked, .gitkeep allowed) |
| **Configuration** | **PASS** | `entrypoint.sh` correctly generated `openclaw.json` with token. |
| **Opencode Fallback** | **PASS** | `.env` created for Opencode with primary model and keys. |

## Deployment Verification Test Case

Follow these steps once deployed in Dokploy to ensure the OpenClaw Gateway is operating correctly in Docker-in-Docker mode.

### 1. Verification of Tools
Access the container terminal and run:
```bash
# Verify Python/UV
uv --version

# Verify GitHub CLI
gh --version

# Verify Docker Access (The "Docker-in-Docker" requirement)
docker ps
```
*Expected Result: All commands return versions/output without "command not found" or "permission denied" (socket error).*

### 2. Verification of OpenClaw Gateway
Check the logs to ensure the gateway started with the preconfigured token:
```bash
# Verify OpenClaw Gateway
cat /home/node/.openclaw/openclaw.json

# Verify Opencode CLI
opencode --help
```
*Expected Result: All commands return versions/output without "command not found" or "permission denied" (socket error). Opencode should display its help menu.*

### 3. Verification of Sandbox Docker Capability
Ask the OpenClaw agent to perform a docker-related task, for example:
> "Run a hello-world docker container and tell me the output."

*Expected Result: OpenClaw should be able to execute the docker command through its native command skill and return the success message.*

### 4. Verification of Opencode Capability
Ask the OpenClaw agent to use the `opencode` tool:
> "Use the opencode command to list the files in the current directory and explain what this repo is about."

*Expected Result: OpenClaw should be able to execute `opencode` and return its output.*

### 5. Opencode Fallback & Knowledge Test
Run this specific command in the container terminal to verify that the environment variables and configuration are correctly "nailed":
```bash
# Test 1: Verify environment variables are exported
echo $OPENAI_MODEL

# Test 2: Verify the generated .env file
cat /home/node/.env

# Test 3: Run opencode with a specific query about the codebase
# This verifies that opencode can read the repo and use the fallback LLM
opencode "Analyze the entrypoint.sh script and summarize how it handles OpenClaw and Opencode configuration."
```
*Expected Result:*
1. `$OPENAI_MODEL` should match your `OPENAI_DEFAULT_MODEL`.
2. `/home/node/.env` should contain the correct keys and base URL.
3. `opencode` should successfully return a summary of the `entrypoint.sh` logic, proving it has LLM access and repo-reading capability.

### 6. Connection & Auth Test (UI Pairing)
Verify that the gateway does not block Control UI connections with a pairing requirement.
1. Deploy the gateway and access the OpenClaw Control UI (web).
2. Connect using the WebSocket URL and the `OPENCLAW_GATEWAY_TOKEN`.
3. Observe if a "pairing required" (1008) error occurs.

*Expected Result: The connection should succeed immediately without prompting for a pairing code, as `pairing: false` and `pairingRequired: false` are explicitly set in the config.*

### 7. Regression: Pairing Required (1008) Fix
A regression was identified where `pairing: false` alone was insufficient to stop the `pairing required` 1008 closure in some environments.
*   **Symptom**: `[ws] closed before connect ... code=1008 reason=pairing required`
*   **Fix**: Added `gateway.pairingRequired: false` to the configuration schema.
*   **Verification**: Ensure logs show successful connection from remote IPs behind reverse proxies (e.g., `origin=https://openclaw-xb5joc.uxible.io`).

## Failure Logs
*Currently: No failures recorded. All environment and build tests passed during the upgrade session.*
