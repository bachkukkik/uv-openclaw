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

# 2. Install OpenClaw at build time
# We use the official installer with flags to skip interactive bits
ENV OPENCLAW_NO_ONBOARD=1
ENV OPENCLAW_NO_PROMPT=1
ENV OPENCLAW_INSTALL_SH_NO_RUN=1
RUN curl -fsSL https://openclaw.ai/install.sh | bash

# Create a redundant copy in a standard location to ensure it survives volume mounts
RUN cp $(find /root/.openclaw/bin -name openclaw) /usr/bin/openclaw-core && \
    chmod +x /usr/bin/openclaw-core

# 3. Add configuration script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 4. Set environment
RUN mkdir -p /home/node/.openclaw
ENV HOME=/home/node
WORKDIR /home/node
ENV TERM=xterm-256color
ENV PATH="/root/.openclaw/bin:/home/node/.openclaw/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

EXPOSE 18789

ENTRYPOINT ["/entrypoint.sh"]
