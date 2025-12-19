#!/bin/bash
set -e

# This script runs as ROOT. It configures permissions, then drops to 'coder' user via gosu.

SOCKET="/var/run/docker.sock"
TARGET_UID=${PUID:-1000}
TARGET_GID=${PGID:-1000}

echo "========================================"
echo "Antigravity Server - Initializing..."
echo "Target UID: $TARGET_UID, GID: $TARGET_GID"
echo "========================================"

# --- 1. User/Group Mapping ---
CURRENT_UID=$(id -u coder)
CURRENT_GID=$(getent group coder | cut -d: -f3)

if [ "$CURRENT_GID" != "$TARGET_GID" ]; then
    echo "[Setup] Updating 'coder' group GID to $TARGET_GID"
    groupmod -o -g "$TARGET_GID" coder
fi

if [ "$CURRENT_UID" != "$TARGET_UID" ]; then
    echo "[Setup] Updating 'coder' user UID to $TARGET_UID"
    usermod -o -u "$TARGET_UID" coder
fi

# Fix home directory ownership (only if needed)
if [ "$(stat -c '%u' /home/coder)" != "$TARGET_UID" ]; then
    echo "[Setup] Fixing /home/coder ownership..."
    chown -R coder:coder /home/coder
fi

# Fix workspace ownership
if [ -d /workspace ] && [ "$(stat -c '%u' /workspace)" != "$TARGET_UID" ]; then
    echo "[Setup] Fixing /workspace ownership..."
    chown coder:coder /workspace
fi

# --- 2. Docker Socket Access ---
if [ -S "$SOCKET" ]; then
    SOCKET_GID=$(stat -c '%g' "$SOCKET")
    
    if getent group docker > /dev/null 2>&1; then
        CURRENT_DOCKER_GID=$(getent group docker | cut -d: -f3)
        if [ "$CURRENT_DOCKER_GID" != "$SOCKET_GID" ]; then
            echo "[Setup] Syncing 'docker' group GID to $SOCKET_GID"
            groupmod -o -g "$SOCKET_GID" docker
        fi
    else
        echo "[Setup] Creating 'docker' group with GID $SOCKET_GID"
        groupadd -g "$SOCKET_GID" docker
    fi

    if ! id -nG coder | grep -qw docker; then
        echo "[Setup] Adding 'coder' to 'docker' group"
        usermod -aG docker coder
    fi
else
    echo "[Warning] Docker socket not found at $SOCKET"
fi

# --- 3. Timezone ---
if [ -n "$TZ" ]; then
    echo "[Setup] Setting timezone to $TZ"
    ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime
    echo "$TZ" > /etc/timezone
fi

echo "[Setup] Initialization complete. Dropping to 'coder' user..."
echo "========================================"

# Drop privileges and execute the command as 'coder'
exec gosu coder "$@"
