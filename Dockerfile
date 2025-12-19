FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install essential tools + gosu for proper privilege dropping
RUN apt-get update && apt-get install -y \
    curl \
    git \
    docker.io \
    sudo \
    vim \
    nano \
    iputils-ping \
    dnsutils \
    ca-certificates \
    openssh-client \
    gnupg \
    lsb-release \
    gosu \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Install VS Code CLI (with ARM64 support)
ARG TARGETARCH
RUN ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "cli-linux-arm64" || echo "cli-linux-x64") && \
    curl -sL "https://code.visualstudio.com/sha/download?build=stable&os=$ARCH" \
    --output /tmp/vscode-cli.tar.gz && \
    tar -xf /tmp/vscode-cli.tar.gz -C /usr/local/bin && \
    rm /tmp/vscode-cli.tar.gz

# Create a non-root user "coder" (will be remapped at runtime)
RUN useradd -m -s /bin/bash -u 1000 -U coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace

# Entrypoint runs as root, then drops to coder via gosu
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["code", "tunnel", "--accept-server-license-terms"]
