ARG UV_IMAGE_TAG=python3.14-bookworm-slim
FROM ghcr.io/astral-sh/uv:${UV_IMAGE_TAG}

# 1. Install system deps, Node.js (for config script), and GH CLI
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    procps \
    gnupg \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update && apt-get install -y gh nodejs \
    && rm -rf /var/lib/apt/lists/*

# 2. Install OpenClaw
RUN mkdir -p /usr/local/lib/npm-global
ENV NPM_CONFIG_PREFIX=/usr/local/lib/npm-global
ENV PATH="${NPM_CONFIG_PREFIX}/bin:${PATH}"
RUN npm install -g openclaw --unsafe-perm
RUN ls -l /usr/local/lib/npm-global/bin/openclaw

# 3. Add configuration script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 4. Set environment
RUN mkdir -p /home/node
ENV HOME=/home/node
WORKDIR /home/node
ENV TERM=xterm-256color
# Include standard npm global bin path and OpenClaw legacy paths
ENV PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/root/.openclaw/bin:/home/node/.openclaw/bin:$PATH"

EXPOSE 18789

ENTRYPOINT ["/entrypoint.sh"]
