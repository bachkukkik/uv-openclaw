ARG UV_IMAGE_TAG=python3.14-bookworm-slim
FROM ghcr.io/astral-sh/uv:${UV_IMAGE_TAG}

# 1. Install system deps, Node.js, and GH CLI
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
# We use npm install -g and verify the binary location
RUN npm install -g openclaw --unsafe-perm && \
    ls -l $(npm config get prefix)/bin/openclaw && \
    ln -sf $(npm config get prefix)/bin/openclaw /usr/bin/openclaw

# 3. Add configuration script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 4. Set environment
RUN mkdir -p /home/node/.openclaw
ENV HOME=/home/node
WORKDIR /home/node
ENV TERM=xterm-256color
# Ensure /usr/bin is in PATH (where we linked the binary)
ENV PATH="/usr/bin:/usr/local/bin:/bin:$PATH"

EXPOSE 18789

ENTRYPOINT ["/entrypoint.sh"]
