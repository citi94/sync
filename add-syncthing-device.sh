#!/bin/bash
# Adds a new device to Mac Mini's Syncthing and shares claude-sync folder
# Called remotely via: ssh mac-mini "~/projects/sync/add-syncthing-device.sh DEVICE_ID DEVICE_NAME"

DEVICE_ID="$1"
DEVICE_NAME="$2"

if [ -z "$DEVICE_ID" ] || [ -z "$DEVICE_NAME" ]; then
    echo "Usage: $0 <device-id> <device-name>"
    exit 1
fi

# Get API key from config
CONFIG_FILE="$HOME/Library/Application Support/Syncthing/config.xml"
API_KEY=$(sed -n 's/.*<apikey>\([^<]*\)<\/apikey>.*/\1/p' "$CONFIG_FILE" | head -1)
API_URL="http://127.0.0.1:8384/rest"

if [ -z "$API_KEY" ]; then
    echo "ERROR: Could not get Syncthing API key"
    exit 1
fi

# Check if device already exists
if curl -s -H "X-API-Key: $API_KEY" "$API_URL/config/devices" | grep -q "$DEVICE_ID"; then
    echo "Device $DEVICE_NAME already registered"
else
    # Add the device
    echo "Adding device: $DEVICE_NAME"
    curl -s -X POST -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
        "$API_URL/config/devices" \
        -d "{\"deviceID\": \"$DEVICE_ID\", \"name\": \"$DEVICE_NAME\", \"addresses\": [\"dynamic\"], \"autoAcceptFolders\": true}"
    echo "Device added"
fi

# Share claude-sync folder with the device
echo "Sharing claude-sync folder..."

# Get current folder config
FOLDER_CONFIG=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/config/folders/claude-sync")

# Check if device already in folder
if echo "$FOLDER_CONFIG" | grep -q "$DEVICE_ID"; then
    echo "Folder already shared with $DEVICE_NAME"
else
    # Add device to folder's device list using PATCH
    curl -s -X PATCH -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
        "$API_URL/config/folders/claude-sync" \
        -d "{\"devices\": [{\"deviceID\": \"$DEVICE_ID\"}]}" 2>/dev/null

    # Alternative: use the CLI if available
    if command -v syncthing &> /dev/null; then
        syncthing cli config folders claude-sync devices add --device-id "$DEVICE_ID" 2>/dev/null || true
    fi

    echo "Folder shared"
fi

echo "Done! $DEVICE_NAME can now sync claude-sync folder"
