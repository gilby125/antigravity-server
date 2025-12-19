# Antigravity Server

A bulletproof, Dockerized setup for running VS Code Server (Remote Tunnels). This allows you to securely access your development environment and server resources from any VS Code client (Desktop or Web) without dealing with SSH keys or firewalls.

## Features
- **Docker-in-Docker Control**: Full access to the host's Docker daemon.
- **Persistence**: Extensions, settings, and authentication survive container restarts.
- **Dynamic Permissions**: Automatically maps the container user (`coder`) to your host user's UID/GID. No more `root` owned files cluttering your workspace!
- **Secure**: Uses VS Code Remote Tunnels (GitHub Authentication).

## Prerequisites
- Docker & Docker Compose installed on the host server.

## Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/gilby125/antigravity-server.git
    cd antigravity-server
    ```

2.  **Configure Permissions (Optional but Recommended)**:
    By default, it uses UID/GID 1000. If your user ID is different (run `id -u`), set it in a `.env` file or export it:
    ```bash
    export PUID=$(id -u)
    export PGID=$(id -g)
    ```

3.  **Start the server**:
    ```bash
    docker compose up -d
    ```

4.  **Authenticate**:
    The first time you run this, you need to link it to your GitHub account.
    View the logs to get the login code:
    ```bash
    docker compose logs -f antigravity
    ```
    - Go to [https://github.com/login/device](https://github.com/login/device)
    - Enter the 8-character code shown in the logs.

## Usage

1.  Open VS Code on your local machine.
2.  Install the **Remote - Tunnels** extension.
3.  Click the Remote Explorer icon (or green button in bottom left) and choose **Connect to Tunnel...**.
4.  Select `antigravity-server`.

You now have full access to your server's filesystem and Docker environment directly from your local VS Code!
