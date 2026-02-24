ARG OPENCLAW_IMAGE=alpine/openclaw:main
FROM ${OPENCLAW_IMAGE}

USER root

# 1. Setup repositories for Docker CLI and GH CLI
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# 2. Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    procps \
    build-essential \
    jq \
    vim \
    docker-ce-cli \
    gh \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# 3. Enable corepack and install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# 4. Create openclaw symlink for compatibility with entrypoint.sh
# The base image has app in /app and uses scripts/run-node.mjs
RUN printf '#!/bin/sh\ncd /app && node /app/scripts/run-node.mjs "$@"' > /usr/local/bin/openclaw && \
    chmod +x /usr/local/bin/openclaw

# 5. Install uv (with explicit path)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# 6. Install Opencode
RUN curl -fsSL https://opencode.ai/install | bash

# 7. Install Openspec
RUN npm install -g @fission-ai/openspec@latest

# 7. Setup environment
ENV HOME=/home/node
ENV CI=true
ENV TERM=xterm-256color
# Add all possible OpenClaw/uv/opencode paths to PATH
ENV PATH=$PATH:/root/.openclaw/bin:/home/node/.openclaw/bin:/root/.opencode/bin:/root/.cargo/bin:/root/.local/bin

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /app
EXPOSE 18789

ENTRYPOINT ["/entrypoint.sh"]

