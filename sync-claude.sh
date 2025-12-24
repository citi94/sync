#!/bin/bash

# Claude Code Conversation Sync
# Syncs ~/.claude/ between machines over Tailscale SSH

set -e

PRIMARY_HOST="mac-mini"  # Tailscale hostname of primary machine
CLAUDE_DIR="$HOME/.claude"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Check if we're on the primary machine
is_primary() {
    [[ "$(hostname -s)" == *"mac-mini"* ]] || [[ "$(scutil --get LocalHostName 2>/dev/null)" == *"Mac-mini"* ]]
}

# Push local conversations TO primary
push_to_primary() {
    if is_primary; then
        error "You're on the primary machine. Use 'pull' on other machines instead."
        exit 1
    fi
    
    log "Pushing ~/.claude/ to $PRIMARY_HOST..."
    rsync -avz --progress \
        --exclude '.credentials.json' \
        --exclude 'statsig/' \
        "$CLAUDE_DIR/" "$PRIMARY_HOST:$CLAUDE_DIR/"
    
    log "Push complete!"
}

# Pull conversations FROM primary
pull_from_primary() {
    if is_primary; then
        error "You're on the primary machine. Other machines pull from you."
        exit 1
    fi
    
    log "Pulling ~/.claude/ from $PRIMARY_HOST..."
    rsync -avz --progress \
        --exclude '.credentials.json' \
        --exclude 'statsig/' \
        "$PRIMARY_HOST:$CLAUDE_DIR/" "$CLAUDE_DIR/"
    
    log "Pull complete!"
}

# Bidirectional sync (merge)
sync_bidirectional() {
    if is_primary; then
        error "Bidirectional sync should be run from secondary machines."
        exit 1
    fi
    
    log "Syncing ~/.claude/ bidirectionally with $PRIMARY_HOST..."
    
    # First pull (get remote changes)
    rsync -avz --progress \
        --exclude '.credentials.json' \
        --exclude 'statsig/' \
        "$PRIMARY_HOST:$CLAUDE_DIR/" "$CLAUDE_DIR/"
    
    # Then push (send local changes)
    rsync -avz --progress \
        --exclude '.credentials.json' \
        --exclude 'statsig/' \
        "$CLAUDE_DIR/" "$PRIMARY_HOST:$CLAUDE_DIR/"
    
    log "Bidirectional sync complete!"
}

# Show status
show_status() {
    info "Local ~/.claude/ stats:"
    echo "  Projects: $(ls -1 "$CLAUDE_DIR/projects/" 2>/dev/null | wc -l | tr -d ' ')"
    echo "  Sessions: $(find "$CLAUDE_DIR/projects/" -name "*.jsonl" 2>/dev/null | wc -l | tr -d ' ')"
    echo "  Size: $(du -sh "$CLAUDE_DIR" 2>/dev/null | cut -f1)"
    
    if ! is_primary; then
        echo ""
        info "Primary machine ($PRIMARY_HOST):"
        ssh "$PRIMARY_HOST" "echo \"  Projects: \$(ls -1 ~/.claude/projects/ 2>/dev/null | wc -l | tr -d ' ')\"; echo \"  Sessions: \$(find ~/.claude/projects/ -name '*.jsonl' 2>/dev/null | wc -l | tr -d ' ')\"; echo \"  Size: \$(du -sh ~/.claude 2>/dev/null | cut -f1)\""
    fi
}

usage() {
    echo "Claude Code Conversation Sync"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  push     Push local conversations to primary ($PRIMARY_HOST)"
    echo "  pull     Pull conversations from primary"
    echo "  sync     Bidirectional sync (pull then push)"
    echo "  status   Show conversation stats"
    echo ""
    echo "Primary machine: $PRIMARY_HOST"
}

case "${1:-}" in
    push)   push_to_primary ;;
    pull)   pull_from_primary ;;
    sync)   sync_bidirectional ;;
    status) show_status ;;
    -h|--help) usage ;;
    *)
        usage
        exit 1
        ;;
esac
