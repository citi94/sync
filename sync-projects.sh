#!/bin/bash

# Project Sync Script for Multiple Computer Development
# Author: citi94
# Purpose: Sync all projects between local machine and GitHub

set -e

GITHUB_USERNAME="citi94"
PROJECTS_DIR="/Users/peter/Projects"
LOG_FILE="$PROJECTS_DIR/sync.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if GitHub CLI is installed
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI (gh) is not installed. Please install it first:"
        error "  brew install gh"
        error "  or visit: https://cli.github.com"
        exit 1
    fi
    
    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        error "Please authenticate with GitHub CLI first:"
        error "  gh auth login"
        exit 1
    fi
}

# Check if a GitHub repository exists
repo_exists() {
    local repo_name="$1"
    gh repo view "$GITHUB_USERNAME/$repo_name" &> /dev/null
}

# Create GitHub repository
create_github_repo() {
    local repo_name="$1"
    local repo_path="$2"
    
    info "Creating GitHub repository: $repo_name"
    
    cd "$repo_path"
    
    # Initialize git if not already initialized
    if [ ! -d ".git" ]; then
        git init
        git branch -M main
    fi
    
    # Create .gitignore if it doesn't exist
    if [ ! -f ".gitignore" ]; then
        echo "node_modules/" > .gitignore
        echo ".env" >> .gitignore
        echo ".DS_Store" >> .gitignore
        echo "*.log" >> .gitignore
    fi
    
    # Add all files
    git add .
    
    # Create initial commit if needed
    if ! git rev-parse HEAD &> /dev/null; then
        git commit -m "Initial commit"
    fi
    
    # Create GitHub repository
    gh repo create "$repo_name" --public --source=. --remote=origin --push
    
    log "Created and pushed repository: $repo_name"
}

# Sync existing repository
sync_repo() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    
    cd "$repo_path"
    
    info "Syncing repository: $repo_name"
    
    # Check if we have a remote
    if ! git remote get-url origin &> /dev/null; then
        warning "No remote found for $repo_name, skipping sync"
        return
    fi
    
    # Stash any local changes
    local stash_created=false
    if [ -n "$(git status --porcelain)" ]; then
        git stash push -m "Auto-stash before sync $(date)"
        stash_created=true
        info "Stashed local changes in $repo_name"
    fi
    
    # Fetch latest changes
    git fetch origin
    
    # Get current branch
    local current_branch=$(git branch --show-current)
    
    # Pull latest changes
    if git show-ref --verify --quiet refs/remotes/origin/$current_branch; then
        git pull origin "$current_branch"
        log "Pulled latest changes for $repo_name"
    else
        warning "Remote branch $current_branch not found for $repo_name"
    fi
    
    # Restore stashed changes if any
    if [ "$stash_created" = true ]; then
        if git stash pop; then
            info "Restored stashed changes in $repo_name"
        else
            warning "Could not restore stashed changes in $repo_name - please resolve manually"
        fi
    fi
    
    # Push any local commits
    if [ -n "$(git log origin/$current_branch..$current_branch --oneline)" ]; then
        git push origin "$current_branch"
        log "Pushed local changes for $repo_name"
    fi
    
    # Return to projects directory
    cd "$PROJECTS_DIR"
}

# Main sync function
sync_all_projects() {
    log "Starting project sync..."
    
    check_gh_cli
    
    cd "$PROJECTS_DIR"
    
    # Find all directories (potential projects)
    for dir in */; do
        if [ -d "$dir" ]; then
            repo_name=$(basename "$dir")
            repo_path="$PROJECTS_DIR/$repo_name"
            
            # Skip if directory name starts with .
            if [[ $repo_name == .* ]]; then
                continue
            fi
            
            info "Processing: $repo_name"
            
            if [ -d "$repo_path/.git" ]; then
                # Existing git repository
                if repo_exists "$repo_name"; then
                    sync_repo "$repo_path"
                else
                    warning "Local git repo $repo_name exists but no GitHub repo found"
                    read -p "Create GitHub repository for $repo_name? (y/n): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        create_github_repo "$repo_name" "$repo_path"
                    fi
                fi
            else
                # Not a git repository
                if repo_exists "$repo_name"; then
                    warning "GitHub repo $repo_name exists but no local git repo"
                    read -p "Clone GitHub repository $repo_name? (y/n): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        mv "$repo_path" "${repo_path}.backup"
                        gh repo clone "$GITHUB_USERNAME/$repo_name" "$repo_path"
                        log "Cloned repository: $repo_name"
                    fi
                else
                    # Neither local git nor GitHub repo exists
                    read -p "Create git repository and push $repo_name to GitHub? (y/n): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        create_github_repo "$repo_name" "$repo_path"
                    fi
                fi
            fi
        fi
    done
    
    log "Project sync completed!"
}

# Quick sync function (non-interactive)
quick_sync() {
    log "Starting quick sync (non-interactive)..."
    
    check_gh_cli
    
    cd "$PROJECTS_DIR"
    
    # Only sync existing git repositories
    for dir in */; do
        if [ -d "$dir" ]; then
            repo_name=$(basename "$dir")
            repo_path="$PROJECTS_DIR/$repo_name"
            
            # Skip if directory name starts with .
            if [[ $repo_name == .* ]]; then
                continue
            fi
            
            if [ -d "$repo_path/.git" ]; then
                sync_repo "$repo_path"
            fi
        fi
    done
    
    log "Quick sync completed!"
}

# Show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -q, --quick     Quick sync (only sync existing repos, non-interactive)"
    echo "  -s, --status    Show status of all repositories"
    echo "  -b, --bootstrap Bootstrap analysis for new machine setup"
    echo ""
    echo "Default behavior: Interactive sync of all projects"
}

# Bootstrap analysis for new machine setup
bootstrap_analysis() {
    log "🔍 Analyzing current setup for bootstrap..."
    
    check_gh_cli
    
    cd "$PROJECTS_DIR"
    
    # Header
    echo -e "\n${BLUE}📊 Bootstrap Analysis Report${NC}"
    echo -e "${BLUE}═══════════════════════════════${NC}"
    
    # Table header
    printf "%-20s %-15s %-15s %-20s\n" "Project" "Local Status" "GitHub Status" "Proposed Action"
    echo "────────────────────────────────────────────────────────────────────────────"
    
    local action_count=0
    local actions=()
    
    # Scan local directories
    for dir in */; do
        if [ -d "$dir" ]; then
            repo_name=$(basename "$dir")
            repo_path="$PROJECTS_DIR/$repo_name"
            
            if [[ $repo_name == .* ]]; then
                continue
            fi
            
            local_status=""
            github_status=""
            proposed_action=""
            
            # Check local status
            if [ -d "$repo_path/.git" ]; then
                if git -C "$repo_path" remote get-url origin &> /dev/null; then
                    local_status="Git+Remote"
                else
                    local_status="Git Only"
                fi
            else
                local_status="No Git"
            fi
            
            # Check GitHub status
            if repo_exists "$repo_name"; then
                github_status="Exists"
            else
                github_status="Missing"
            fi
            
            # Determine proposed action
            if [ "$local_status" = "Git+Remote" ] && [ "$github_status" = "Exists" ]; then
                proposed_action="Sync"
            elif [ "$local_status" = "Git Only" ] && [ "$github_status" = "Missing" ]; then
                proposed_action="Create GitHub"
                action_count=$((action_count + 1))
            elif [ "$local_status" = "No Git" ] && [ "$github_status" = "Exists" ]; then
                proposed_action="Clone (backup local)"
                action_count=$((action_count + 1))
            elif [ "$local_status" = "No Git" ] && [ "$github_status" = "Missing" ]; then
                proposed_action="Create both"
                action_count=$((action_count + 1))
            else
                proposed_action="Review needed"
                action_count=$((action_count + 1))
            fi
            
            printf "%-20s %-15s %-15s %-20s\n" "$repo_name" "$local_status" "$github_status" "$proposed_action"
            actions+=("$repo_name:$proposed_action")
        fi
    done
    
    # Check for GitHub repos not present locally
    echo -e "\n${BLUE}🔍 Checking for GitHub repos not present locally...${NC}"
    
    # Get list of user's repositories
    local missing_repos=()
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        while read -r repo_name; do
            if [ ! -d "$PROJECTS_DIR/$repo_name" ]; then
                printf "%-20s %-15s %-15s %-20s\n" "$repo_name" "Missing" "Exists" "Clone"
                missing_repos+=("$repo_name")
                action_count=$((action_count + 1))
            fi
        done < <(gh repo list "$GITHUB_USERNAME" --limit 100 --json name -q '.[].name')
    fi
    
    echo
    if [ $action_count -eq 0 ]; then
        echo -e "${GREEN}✅ All projects are already in sync!${NC}"
    else
        echo -e "${YELLOW}📋 Found $action_count projects that need attention${NC}"
        echo
        echo "Choose an action:"
        echo "  ${GREEN}a${NC} - Accept all proposed actions"
        echo "  ${YELLOW}s${NC} - Selective mode (choose individually)"
        echo "  ${BLUE}c${NC} - Clone missing repos only"
        echo "  ${RED}q${NC} - Quit without changes"
        echo
        read -p "Your choice [a/s/c/q]: " -n 1 -r
        echo
        
        case $REPLY in
            a|A)
                log "Executing all proposed actions..."
                sync_all_projects
                ;;
            s|S)
                log "Entering selective mode..."
                sync_all_projects  # This already has interactive prompts
                ;;
            c|C)
                log "Cloning missing repositories only..."
                clone_missing_repos
                ;;
            q|Q)
                log "Bootstrap cancelled by user"
                ;;
            *)
                error "Invalid choice"
                ;;
        esac
    fi
}

# Clone missing repositories only
clone_missing_repos() {
    cd "$PROJECTS_DIR"
    
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        gh repo list "$GITHUB_USERNAME" --limit 100 --json name -q '.[].name' | while read -r repo_name; do
            if [ ! -d "$PROJECTS_DIR/$repo_name" ]; then
                info "Cloning $repo_name..."
                gh repo clone "$GITHUB_USERNAME/$repo_name" "$repo_name"
            fi
        done
    fi
}

# Show repository status
show_status() {
    log "Checking repository status..."
    
    cd "$PROJECTS_DIR"
    
    for dir in */; do
        if [ -d "$dir" ]; then
            repo_name=$(basename "$dir")
            repo_path="$PROJECTS_DIR/$repo_name"
            
            if [[ $repo_name == .* ]]; then
                continue
            fi
            
            echo -e "\n${BLUE}=== $repo_name ===${NC}"
            
            if [ -d "$repo_path/.git" ]; then
                cd "$repo_path"
                
                # Check if remote exists
                if git remote get-url origin &> /dev/null; then
                    echo -e "${GREEN}✓${NC} Git repository with remote"
                    
                    # Check for uncommitted changes
                    if [ -n "$(git status --porcelain)" ]; then
                        echo -e "${YELLOW}!${NC} Uncommitted changes"
                    else
                        echo -e "${GREEN}✓${NC} Clean working directory"
                    fi
                    
                    # Check for unpushed commits
                    current_branch=$(git branch --show-current)
                    if git show-ref --verify --quiet refs/remotes/origin/$current_branch; then
                        if [ -n "$(git log origin/$current_branch..$current_branch --oneline)" ]; then
                            echo -e "${YELLOW}!${NC} Unpushed commits"
                        else
                            echo -e "${GREEN}✓${NC} Up to date with remote"
                        fi
                    else
                        echo -e "${RED}✗${NC} Remote branch not found"
                    fi
                else
                    echo -e "${YELLOW}!${NC} Git repository without remote"
                fi
                
                cd "$PROJECTS_DIR"
            else
                echo -e "${RED}✗${NC} Not a git repository"
            fi
        fi
    done
}

# Main script logic
case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    -q|--quick)
        quick_sync
        ;;
    -s|--status)
        show_status
        ;;
    -b|--bootstrap)
        bootstrap_analysis
        ;;
    "")
        sync_all_projects
        ;;
    *)
        error "Unknown option: $1"
        usage
        exit 1
        ;;
esac