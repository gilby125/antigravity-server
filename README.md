# Antigravity Server

A bulletproof, Dockerized setup for running VS Code Server (Remote Tunnels). Securely access your development environment from any VS Code client without SSH keys or firewalls.

## Features

| Feature | Description |
|---------|-------------|
| **Docker Control** | Full access to the host's Docker daemon |
| **Persistence** | Extensions, settings, and auth survive restarts |
| **Dynamic Permissions** | Maps container user to your host UID/GID |
| **ARM64 Support** | Works on both x86_64 and ARM64 hosts |
| **SSH Agent Forwarding** | Seamless Git authentication |
| **Timezone** | Configurable TZ for correct timestamps |
| **Healthcheck** | Built-in health monitoring |

## Quick Start

```bash
# Clone
git clone https://github.com/gilby125/antigravity-server.git
cd antigravity-server

# Configure (copy and edit)
cp .env.example .env
# Edit .env: set PUID, PGID (run `id -u` and `id -g`)

# Start
docker compose up -d

# Authenticate (first time only)
docker compose logs -f antigravity
# Go to https://github.com/login/device and enter the code
```

## Configuration

Copy `.env.example` to `.env` and customize:

| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` | 1000 | Your user ID (`id -u`) |
| `PGID` | 1000 | Your group ID (`id -g`) |
| `TZ` | UTC | Timezone (e.g., `America/Chicago`) |
| `CODE_DIR` | `$HOME/code` | Host directory to mount as `/workspace` |
| `TUNNEL_NAME` | `antigravity-server` | Name shown in VS Code |
| `SSH_AUTH_SOCK` | - | SSH agent socket path for Git auth |

## Usage

1. Open VS Code on your local machine
2. Install the **Remote - Tunnels** extension
3. Click Remote Explorer → **Connect to Tunnel...**
4. Select your tunnel name

## Building for ARM64

```bash
docker buildx build --platform linux/arm64 -t antigravity-server:latest .
```

## License

MIT
