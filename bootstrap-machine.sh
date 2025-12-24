#!/bin/bash
# Bootstrap script for Claude Code sync on any Tailscale-connected machine
# Works on macOS and Linux

set -e

# Mac Mini's Syncthing Device ID (primary sync hub)
MAC_MINI_DEVICE_ID="RX4OYLQ-YZNAZ6V-5C3VTHZ-UTSYUJU-EWMAF5R-ITSXIDA-7VJMG7C-3DDCSQX"
MAC_MINI_NAME="mac-mini"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Claude Code Sync Bootstrap ===${NC}"
echo ""

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    CONFIG_DIR="$HOME/Library/Application Support/Syncthing"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    CONFIG_DIR="$HOME/.config/syncthing"
    # Detect distro
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    fi
else
    echo -e "${RED}Unsupported OS: $OSTYPE${NC}"
    exit 1
fi
echo -e "Detected OS: ${GREEN}$OS${NC}"

# Check Tailscale
if command -v tailscale &> /dev/null; then
    if tailscale status &> /dev/null; then
        echo -e "${GREEN}✓ Tailscale connected${NC}"
    else
        echo -e "${YELLOW}! Tailscale installed but not connected${NC}"
    fi
else
    echo -e "${YELLOW}! Tailscale not installed - install it for remote sync${NC}"
fi

# ===== Install Syncthing =====
echo ""
echo -e "${BLUE}[1/4] Installing Syncthing...${NC}"

if command -v syncthing &> /dev/null; then
    echo -e "${GREEN}✓ Syncthing already installed${NC}"
else
    if [ "$OS" == "macos" ]; then
        if ! command -v brew &> /dev/null; then
            echo -e "${RED}Homebrew required. Install from https://brew.sh${NC}"
            exit 1
        fi
        brew install syncthing
    elif [ "$OS" == "linux" ]; then
        case $DISTRO in
            ubuntu|debian|pop)
                sudo apt-get update && sudo apt-get install -y syncthing
                ;;
            fedora|rhel|centos)
                sudo dnf install -y syncthing
                ;;
            arch|manjaro)
                sudo pacman -S --noconfirm syncthing
                ;;
            *)
                echo -e "${RED}Unknown distro: $DISTRO - install Syncthing manually${NC}"
                exit 1
                ;;
        esac
    fi
    echo -e "${GREEN}✓ Syncthing installed${NC}"
fi

# ===== Start Syncthing =====
echo ""
echo -e "${BLUE}[2/4] Starting Syncthing service...${NC}"

if [ "$OS" == "macos" ]; then
    brew services start syncthing 2>/dev/null || true
elif [ "$OS" == "linux" ]; then
    systemctl --user enable syncthing 2>/dev/null || true
    systemctl --user start syncthing 2>/dev/null || true
fi

# Wait for config to be created
echo "Waiting for Syncthing to initialize..."
for i in {1..10}; do
    if [ -f "$CONFIG_DIR/config.xml" ]; then
        break
    fi
    sleep 1
done

if [ ! -f "$CONFIG_DIR/config.xml" ]; then
    echo -e "${RED}Syncthing config not found. Start Syncthing manually and re-run.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Syncthing running${NC}"

# ===== Configure Syncthing =====
echo ""
echo -e "${BLUE}[3/4] Configuring Syncthing...${NC}"

# Get API key from config
API_KEY=$(sed -n 's/.*<apikey>\([^<]*\)<\/apikey>.*/\1/p' "$CONFIG_DIR/config.xml" | head -1)

if [ -z "$API_KEY" ]; then
    echo -e "${YELLOW}Could not get API key automatically.${NC}"
    echo ""
    echo "Manual setup required:"
    echo "1. Open http://127.0.0.1:8384"
    echo "2. Add Remote Device: $MAC_MINI_DEVICE_ID"
    echo "3. Add Folder: id=claude-sync, path=~/.claude"
else
    API_URL="http://127.0.0.1:8384/rest"

    # Create ~/.claude if needed
    mkdir -p ~/.claude

    # Get this device's ID
    MY_DEVICE_ID=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/system/status" 2>/dev/null | grep -o '"myID":"[^"]*"' | cut -d'"' -f4)
    MY_HOSTNAME=$(hostname)

    # Check if Mac Mini device already added locally
    if curl -s -H "X-API-Key: $API_KEY" "$API_URL/config/devices" 2>/dev/null | grep -q "$MAC_MINI_DEVICE_ID"; then
        echo -e "${GREEN}✓ Mac Mini already configured locally${NC}"
    else
        # Add Mac Mini device
        curl -s -X POST -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
            "$API_URL/config/devices" \
            -d "{\"deviceID\": \"$MAC_MINI_DEVICE_ID\", \"name\": \"$MAC_MINI_NAME\", \"addresses\": [\"dynamic\"], \"autoAcceptFolders\": true}" \
            2>/dev/null && echo -e "${GREEN}✓ Mac Mini device added locally${NC}" || echo -e "${YELLOW}! Could not add device via API${NC}"
    fi

    # Check if claude-sync folder exists locally
    if curl -s -H "X-API-Key: $API_KEY" "$API_URL/config/folders" 2>/dev/null | grep -q "claude-sync"; then
        echo -e "${GREEN}✓ claude-sync folder already configured locally${NC}"
    else
        # Add claude-sync folder
        curl -s -X POST -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
            "$API_URL/config/folders" \
            -d "{\"id\": \"claude-sync\", \"label\": \"Claude Code\", \"path\": \"$HOME/.claude\", \"devices\": [{\"deviceID\": \"$MY_DEVICE_ID\"}, {\"deviceID\": \"$MAC_MINI_DEVICE_ID\"}]}" \
            2>/dev/null && echo -e "${GREEN}✓ claude-sync folder added locally${NC}" || echo -e "${YELLOW}! Could not add folder via API${NC}"
    fi

    # Register this device on Mac Mini via Tailscale SSH
    echo -e "${BLUE}Registering with Mac Mini via Tailscale...${NC}"
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new mac-mini "~/projects/sync/add-syncthing-device.sh '$MY_DEVICE_ID' '$MY_HOSTNAME'" 2>/dev/null; then
        echo -e "${GREEN}✓ Registered with Mac Mini - sync will start automatically${NC}"
        REGISTERED=true
    else
        echo -e "${YELLOW}! Could not reach Mac Mini via Tailscale SSH${NC}"
        echo "  You'll need to accept this device manually on Mac Mini"
        REGISTERED=false
    fi
fi

# ===== Setup GitHub Sync =====
echo ""
echo -e "${BLUE}[4/4] Setting up GitHub project sync...${NC}"

PROJECTS_DIR="$HOME/projects"
mkdir -p "$PROJECTS_DIR"

if [ -d "$PROJECTS_DIR/sync/.git" ]; then
    echo -e "${GREEN}✓ Sync repo exists${NC}"
    (cd "$PROJECTS_DIR/sync" && git pull --quiet 2>/dev/null) || true
else
    echo "Cloning sync repo..."
    git clone https://github.com/citi94/sync.git "$PROJECTS_DIR/sync"
    echo -e "${GREEN}✓ Sync repo cloned${NC}"
fi

# Determine shell config
if [ -f ~/.zshrc ]; then
    SHELL_RC="$HOME/.zshrc"
else
    SHELL_RC="$HOME/.bashrc"
fi

# Add gsync function if not present
if ! grep -q "gsync()" "$SHELL_RC" 2>/dev/null; then
    echo '' >> "$SHELL_RC"
    echo '# ===== Project sync command =====' >> "$SHELL_RC"
    echo 'gsync() {' >> "$SHELL_RC"
    echo '    if [ -d ~/projects/sync/.git ]; then' >> "$SHELL_RC"
    echo '        (cd ~/projects/sync && git pull --quiet 2>/dev/null)' >> "$SHELL_RC"
    echo '    fi' >> "$SHELL_RC"
    echo '    if [ -f ~/projects/sync/sync-projects.sh ]; then' >> "$SHELL_RC"
    echo '        echo "🔄 Syncing projects with GitHub..."' >> "$SHELL_RC"
    echo '        (cd ~/projects && ./sync/sync-projects.sh --quick)' >> "$SHELL_RC"
    echo '        echo "✅ Done"' >> "$SHELL_RC"
    echo '    else' >> "$SHELL_RC"
    echo '        echo "❌ Sync script not found"' >> "$SHELL_RC"
    echo '    fi' >> "$SHELL_RC"
    echo '}' >> "$SHELL_RC"
    echo -e "${GREEN}✓ gsync command added to $SHELL_RC${NC}"
else
    echo -e "${GREEN}✓ gsync command already configured${NC}"
fi

# ===== Done =====
echo ""
echo -e "${GREEN}=== Bootstrap Complete ===${NC}"
echo ""

if [ "$REGISTERED" = true ]; then
    echo -e "${GREEN}Syncthing is configured and will sync automatically.${NC}"
    echo ""
    echo "Your ~/.claude folder will sync with Mac Mini within a few minutes."
else
    echo -e "${YELLOW}Manual step required on Mac Mini:${NC}"
    echo ""
    echo "  1. Open http://mac-mini:8384 (or http://127.0.0.1:8384 on Mac Mini)"
    echo "  2. Accept the 'New Device' request"
    echo "  3. Share the 'claude-sync' folder with it"
fi

echo ""
echo -e "${BLUE}To start working:${NC}"
echo "  source $SHELL_RC"
echo "  gsync    # Sync GitHub projects"
echo "  claude   # Start Claude Code"
