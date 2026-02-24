# Testing & Deployment Verification

This document summarizes the test cases conducted to verify the repository upgrade and provides a manual test case for deployment verification.

## Test Results (Sun Feb 22 2026)

| Test Case | Description | Result |
| --- | --- | --- |
| **Environment Check** | Verify `uv`, `gh`, `node`, and `openclaw` are installed in the image. | **PASS** |
| **DooD Verification** | Verify `docker` CLI and socket access inside the container. | **PASS** |
| **Config Generation** | Verify `entrypoint.sh` generates `openclaw.json` with lean variables. | **PASS** |
| **Git Protection** | Verify `llms_txt/*` is ignored by Git, excluding `.gitkeep`. | **PASS** |
| **Exit 137 Guard** | Verify shell entry no longer triggers onboarding loops or memory spikes. | **PASS** |
| **Auth Alignment** | Verify Dashboard connects via proxy with tokenized URL. | **PASS** |
| **Network Isolation** | Verify no direct host port bindings exist. | **PASS** |

## Full System Check (Automated) - Sun Feb 22 2026

I performed a full system check by building the container and executing verification commands internally.

| Component | Status | Verification Command |
| --- | --- | --- |
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
| **LiteLLM API Fix** | **PASS** | `openai-completions` correctly mapped for LiteLLM providers. |
| **Exit 137 Stability** | **PASS** | Shell access is instantaneous and silent (no memory loops). |
| **Dashboard Auth** | **PASS** | Dashboard connects via tokenized URL on port-isolated network. |

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

### entrypoint.sh

I implemented a robust bypass for the v2026 onboarding TUI by using CI environment variables and input redirection.

#### [entrypoint.sh](file:///Users/bachkukkik/Archives/GitHub_Repo/sandbox/uv-openclaw/volume_openclaw/entrypoint.sh)

```diff
 echo "Starting OpenClaw gateway with manual-aligned config..."
 export OPENCLAW_GATEWAY_NO_ONBOARD=1
 export OPENCLAW_GATEWAY_NO_PROMPT=1
+export CI=true
-exec openclaw gateway run
+exec openclaw gateway run < /dev/null
```

## Verification Results

- **Healthy Status**: The container now reaches a `healthy` state automatically.
- **TUI Bypassed**: Logs confirm the gateway skips the "QuickStart" and "Skills" wizards and starts the listening server immediately.
- **No OOM Crash**: By avoiding the skill scan, memory usage remains within limits (Exit code 137 resolved).

### 6. Connection & Auth Test (Bypass Mode)

Verify that the gateway correctly handles authentication when pairing is disabled.

1. Set `OPENCLAW_GATEWAY_DANGEROUSLY_DISABLE_DEVICE_AUTH=true` and `OPENCLAW_GATEWAY_ALLOW_INSECURE_AUTH=true` in `.env`.
2. Visit your proxy URL with the token: `http://openclaw.yourdomain.com/#token=<your-token>`.
3. *Expected Result: Dashboard connects immediately without a pairing prompt.*

### 7. Stability Test (Exit Code 137 Prevention)

Verify that entering the shell doesn't trigger a crash.

1. Run `docker exec -it <container> bash`.
2. Observe the terminal for ~10 seconds.
3. *Expected Result: No onboarding prompt appears. Shell remains active and stable.*

### 8. Non-Interactive Fresh Deployment

Verify that the gateway can bootstrap from zero without user input.

1. Clear the config: `docker volume rm uv-openclaw_openclaw_config`.
2. Start the container: `docker compose up -d`.
3. Check logs: `docker logs <container>`.
4. *Expected Result: "OpenClaw configuration updated successfully" appears. Gateway starts listening without waiting for input.*

### Case 1: Missing External Network (CF_NETWORK)

- **Scenario**: `CF_NETWORK` is set in `.env` but the network does not exist in Docker.
- **Fail Message**: `network <name> declared as external, but could not be found`.
- **Mitigation**: Verify network exists with `docker network ls` or change `external: true` to `false` in `docker-compose.yml` for local-only testing.

### Case 2: Incomplete LLM Environment

- **Scenario**: `OPENAI_API_BASE` is provided without `OPENAI_API_KEY`.
- **Fail Message**: Gateway may start but agent tasks will fail with `401 Unauthorized`.
- **Verification**: Run `openclaw status --deep` inside the container to check provider health.
