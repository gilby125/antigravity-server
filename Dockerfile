FROM ubuntu:22.04

# Prevent interactive prompts ensuring "bulletproof" non-interactive build
ENV DEBIAN_FRONTEND=noninteractive

# Install essential tools
# docker.io: client to talk to the host socket
# git, curl, wget, unzip: standard tools
# sudo: for the user to run root commands if needed
# vim, nano: for quick edits inside container
# iputils-ping, dnsutils: for networking debugging
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
    && rm -rf /var/lib/apt/lists/*

# Install VS Code CLI
RUN curl -sL "https://code.visualstudio.com/sha/download?build=stable&os=cli-linux-x64" \
    --output /tmp/vscode-cli.tar.gz && \
    tar -xf /tmp/vscode-cli.tar.gz -C /usr/local/bin && \
    rm /tmp/vscode-cli.tar.gz

# Create a non-root user "coder"
RUN useradd -m -s /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER coder
WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["code", "tunnel", "--accept-server-license-terms"]
