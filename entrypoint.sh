#!/bin/bash
set -e

# Goal: Allow the 'coder' user to access the docker socket mounted from the host.
# The socket (/var/run/docker.sock) is owned by root:[host_docker_gid].
# We need to ensure the container's 'docker' group has same GID as the socket.

SOCKET="/var/run/docker.sock"

if [ -S "$SOCKET" ]; then
    # Get the group ID of the socket
    SOCKET_GID=$(stat -c '%g' "$SOCKET")
    
    # Check if the 'docker' group already exists in container
    if getent group docker > /dev/null 2>&1; then
        CURRENT_DOCKER_GID=$(getent group docker | cut -d: -f3)
        if [ "$CURRENT_DOCKER_GID" != "$SOCKET_GID" ]; then
            # GID mismatch. Change container's docker group GID to match host's.
            echo "Changing 'docker' group GID from $CURRENT_DOCKER_GID to $SOCKET_GID to match host socket."
            sudo groupmod -g "$SOCKET_GID" docker || true
        fi
    else
        # Start fresh: create docker group with the correct GID
        echo "Creating 'docker' group with GID $SOCKET_GID."
        sudo groupadd -g "$SOCKET_GID" docker
    fi

    # Ensure the 'coder' user is in the 'docker' group
    if ! groups coder | grep -q '\bdocker\b'; then
        echo "Adding 'coder' user to 'docker' group."
        sudo usermod -aG docker coder
    fi
    
else
    echo "Warning: /var/run/docker.sock not found. Docker commands inside container may fail."
fi

# Execute the passed command (e.g., 'code tunnel ...')
exec "$@"
