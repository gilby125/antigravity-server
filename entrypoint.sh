#!/bin/bash
set -e

# Goal: 
# 1. Allow 'coder' user to access docker socket (Group mapping).
# 2. Map 'coder' user to Host UID/GID to avoid permission issues on files (User mapping).

SOCKET="/var/run/docker.sock"
TARGET_UID=${PUID:-1000}
TARGET_GID=${PGID:-1000}

echo "Starting with UID: $TARGET_UID, GID: $TARGET_GID"

# --- 1. User/Group Mapping (The "nerasse" improvement) ---
# Check if we need to change the 'coder' user UID
CURRENT_UID=$(id -u coder)
if [ "$CURRENT_UID" != "$TARGET_UID" ]; then
    echo "Updating 'coder' UID to $TARGET_UID"
    usermod -o -u "$TARGET_UID" coder
fi

# Check if we need to change the 'coder' group GID
CURRENT_GID=$(getent group coder | cut -d: -f3)
if [ "$CURRENT_GID" != "$TARGET_GID" ]; then
    echo "Updating 'coder' GID to $TARGET_GID"
    groupmod -o -g "$TARGET_GID" coder
fi

# Fix home directory permissions if they drifted
# (Optimized: only chown if ownership is wrong on home dir root)
if [ "$(stat -c '%u' /home/coder)" != "$TARGET_UID" ]; then
    echo "Fixing /home/coder permissions..."
    chown -R coder:coder /home/coder
fi


# --- 2. Docker Socket Access ---
if [ -S "$SOCKET" ]; then
    SOCKET_GID=$(stat -c '%g' "$SOCKET")
    
    # Check if 'docker' group exists
    if getent group docker > /dev/null 2>&1; then
        CURRENT_DOCKER_GID=$(getent group docker | cut -d: -f3)
        if [ "$CURRENT_DOCKER_GID" != "$SOCKET_GID" ]; then
            echo "Changing 'docker' group GID to $SOCKET_GID to match host socket."
            groupmod -g "$SOCKET_GID" docker || true
        fi
    else
        echo "Creating 'docker' group with GID $SOCKET_GID."
        groupadd -g "$SOCKET_GID" docker
    fi

    # Ensure 'coder' is in 'docker' group
    if ! groups coder | grep -q '\bdocker\b'; then
        echo "Adding 'coder' user to 'docker' group."
        usermod -aG docker coder
    fi
else
    echo "Warning: /var/run/docker.sock not found."
fi

# Execute command
exec "$@"
