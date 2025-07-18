#!/bin/bash

# Bootstrap Script for Sync System
# Usage: curl -L https://raw.githubusercontent.com/citi94/sync/main/bootstrap.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[BOOTSTRAP]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Default projects directory
PROJECTS_DIR="$HOME/Projects"

log "🚀 Starting sync system bootstrap..."

# Check if Projects directory exists
if [ ! -d "$PROJECTS_DIR" ]; then
    warning "Projects directory not found at $PROJECTS_DIR"
    read -p "Create Projects directory? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p "$PROJECTS_DIR"
        log "Created Projects directory at $PROJECTS_DIR"
    else
        read -p "Enter custom Projects directory path: " PROJECTS_DIR
        mkdir -p "$PROJECTS_DIR"
    fi
fi

# Check if sync directory already exists
if [ -d "$PROJECTS_DIR/sync" ]; then
    warning "Sync directory already exists at $PROJECTS_DIR/sync"
    read -p "Overwrite existing sync system? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$PROJECTS_DIR/sync"
    else
        log "Bootstrap cancelled"
        exit 0
    fi
fi

# Clone sync repository
log "Cloning sync system from GitHub..."
cd "$PROJECTS_DIR"
git clone https://github.com/citi94/sync.git

# Make scripts executable
chmod +x sync/sync-projects.sh

# Create wrapper script in Projects directory
cat > sync-projects.sh << 'EOF'
#!/bin/bash
# Wrapper script for sync-projects.sh
cd "$(dirname "$0")"
./sync/sync-projects.sh "$@"
EOF

chmod +x sync-projects.sh

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    warning "GitHub CLI (gh) is not installed"
    info "Install with: brew install gh"
    info "Then run: gh auth login"
else
    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        warning "GitHub CLI is not authenticated"
        info "Run: gh auth login"
    else
        log "GitHub CLI is ready"
    fi
fi

log "✅ Bootstrap complete!"
echo
echo "Next steps:"
echo "1. Ensure GitHub CLI is installed and authenticated"
echo "2. Run analysis: ./sync-projects.sh --status"
echo "3. Run full sync: ./sync-projects.sh"
echo "4. For daily use: ./sync-projects.sh --quick"
echo
echo "The sync system is now ready at: $PROJECTS_DIR/sync"