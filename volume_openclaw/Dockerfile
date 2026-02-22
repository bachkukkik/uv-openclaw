ARG UV_IMAGE_TAG=python3.14-bookworm-slim
FROM ghcr.io/astral-sh/uv:${UV_IMAGE_TAG}

# 1. Install system deps, Node.js, GH CLI, and Docker CLI
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    procps \
    gnupg \
    ca-certificates \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update && apt-get install -y gh nodejs docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# 2. Install OpenClaw using the official script
# We allow it to fail the TTY check at the end but ensure the install completes
RUN export NO_ONBOARD=1 && \
    export OPENCLAW_NO_PROMPT=1 && \
    (curl -fsSL https://openclaw.ai/install.sh | bash || true)

# 2.5 Install opencode
RUN curl -fsSL https://opencode.ai/install | bash

# 3. Add configuration script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 4. Set environment
RUN mkdir -p /home/node/.openclaw
ENV HOME=/home/node
WORKDIR /home/node
ENV TERM=xterm-256color
# Add all possible OpenClaw paths to PATH
ENV PATH=$PATH:/root/.openclaw/bin:/home/node/.openclaw/bin:/home/node/.opencode/bin

EXPOSE 18789

ENTRYPOINT ["/entrypoint.sh"]
