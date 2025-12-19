#!/bin/bash
set -euo pipefail

# This script runs as ROOT. It configures permissions, then drops to 'coder' user via gosu.

SOCKET="/var/run/docker.sock"
TARGET_UID="${PUID:-1000}"
TARGET_GID="${PGID:-1000}"
TZ="${TZ:-}"

if ! [[ "$TARGET_UID" =~ ^[0-9]+$ && "$TARGET_GID" =~ ^[0-9]+$ ]]; then
    echo "[Error] PUID and PGID must be numeric (got PUID='$TARGET_UID', PGID='$TARGET_GID')"
    exit 1
fi

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

# --- Workspace Directory ---
# If /workspace doesn't exist or is empty (Docker auto-created it), ensure proper setup
if [ ! -d /workspace ]; then
    echo "[Setup] Creating /workspace directory..."
    mkdir -p /workspace
fi

# Fix workspace ownership if needed
if [ "$(stat -c '%u' /workspace)" != "$TARGET_UID" ]; then
    echo "[Setup] Fixing /workspace ownership..."
    chown coder:coder /workspace
fi

# Friendly warning if workspace is empty
if [ -z "$(ls -A /workspace 2>/dev/null)" ]; then
    echo "[Info] /workspace is empty. Mount your code directory or create projects here."
fi

# --- 2. Docker Socket Access ---
if [ -S "$SOCKET" ]; then
    SOCKET_GID=$(stat -c '%g' "$SOCKET")

    # Prefer using an existing group that already owns the socket GID; avoid mutating group IDs
    # inside the container (which can fail when the GID is already taken).
    SOCKET_GROUP_NAME="$(getent group | awk -F: -v gid="$SOCKET_GID" '$3==gid { print $1; exit }')"
    if [ -n "$SOCKET_GROUP_NAME" ]; then
        DOCKER_ACCESS_GROUP="$SOCKET_GROUP_NAME"
    else
        if getent group docker > /dev/null 2>&1; then
            DOCKER_ACCESS_GROUP="dockersock"
            if getent group "$DOCKER_ACCESS_GROUP" > /dev/null 2>&1; then
                DOCKER_ACCESS_GROUP="dockersock2"
            fi
        else
            DOCKER_ACCESS_GROUP="docker"
        fi

        echo "[Setup] Creating '$DOCKER_ACCESS_GROUP' group with GID $SOCKET_GID"
        groupadd -g "$SOCKET_GID" "$DOCKER_ACCESS_GROUP"
    fi

    echo "[Setup] Docker socket group: '$DOCKER_ACCESS_GROUP' (GID $SOCKET_GID)"
    if ! id -nG coder | grep -qw "$DOCKER_ACCESS_GROUP"; then
        echo "[Setup] Adding 'coder' to '$DOCKER_ACCESS_GROUP' group"
        usermod -aG "$DOCKER_ACCESS_GROUP" coder
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
