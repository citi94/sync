# Project Sync System Documentation

## Overview

This sync system ensures all your projects are synchronized between multiple computers and GitHub. It handles:
- Creating GitHub repositories for local projects
- Syncing existing repositories 
- Pulling latest changes from remote
- Pushing local changes to remote
- Managing uncommitted changes safely

## Files

- `sync-projects.sh` - Main sync script
- `sync.log` - Log file for all sync operations

## Setup

1. **Install GitHub CLI**:
   ```bash
   brew install gh
   ```

2. **Authenticate with GitHub**:
   ```bash
   gh auth login
   ```

3. **Make script executable** (already done):
   ```bash
   chmod +x sync-projects.sh
   ```

## Usage

### Quick Sync (Recommended for daily use)
```bash
./sync-projects.sh --quick
```
This command:
- Syncs all existing git repositories
- Pulls latest changes from GitHub
- Pushes any local commits
- Stashes/restores uncommitted changes safely
- Non-interactive (perfect for daily workflow)

### Full Interactive Sync
```bash
./sync-projects.sh
```
This command:
- Checks all directories in Projects folder
- Offers to create GitHub repos for non-git projects
- Offers to clone missing GitHub repos
- Syncs existing repositories

### Check Status
```bash
./sync-projects.sh --status
```
Shows status of all repositories:
- Git repository status
- Remote connection status
- Uncommitted changes
- Unpushed commits

### Bootstrap Analysis
```bash
./sync-projects.sh --bootstrap
```
Analyzes current setup for new machine bootstrap:
- Shows table of all projects with local/GitHub status
- Provides intelligent recommendations
- Offers batch operations (accept all, selective, clone-only)
- Perfect for setting up development environment on new machines

### Help
```bash
./sync-projects.sh --help
```

## 🚀 New Machine Bootstrap

### One-liner Bootstrap
**Get started on a new machine instantly:**
```bash
curl -L https://raw.githubusercontent.com/citi94/sync/main/bootstrap.sh | bash
```

**Or manual setup:**
```bash
# 1. Create Projects directory
mkdir -p ~/Projects && cd ~/Projects

# 2. Clone sync system
git clone https://github.com/citi94/sync.git

# 3. Run bootstrap analysis
./sync-projects.sh --bootstrap
```

## Claude Code Commands

### Bootstrap Analysis
To analyze current setup and see what needs syncing:
```bash
cd /Users/peter/Projects && ./sync-projects.sh --bootstrap
```

### Daily Sync Command
To sync before developing (recommended workflow):
```bash
cd /Users/peter/Projects && ./sync-projects.sh --quick
```

### Status Check
To check all repository status:
```bash
cd /Users/peter/Projects && ./sync-projects.sh --status
```

### Full Sync (when setting up new machine)
To set up all projects on a new machine:
```bash
cd /Users/peter/Projects && ./sync-projects.sh
```

## How It Works

### 🔄 Bootstrap Process

**Analysis Phase:**
1. Scans existing local projects vs GitHub repositories
2. Shows clear table of what would happen during sync
3. Identifies conflicts and provides recommendations

**Batch Operations:**
- **Accept all**: Execute all proposed actions automatically
- **Selective**: Choose individually for each project
- **Clone-only**: Safe download of missing repositories
- **Smart backup**: Existing directories backed up before cloning

### For Existing Git Repositories:
1. Stashes any uncommitted changes
2. Fetches latest changes from remote
3. Pulls changes to current branch
4. Restores stashed changes
5. Pushes any local commits

### For New Projects:
1. Initializes git repository
2. Creates .gitignore file
3. Makes initial commit
4. Creates GitHub repository
5. Pushes to GitHub

### Safety Features:
- Automatically stashes uncommitted changes before pulling
- Restores stashed changes after sync
- Provides clear logging of all operations
- Interactive prompts for destructive operations
- Backup creation when needed
- Bootstrap analysis before making changes

## Current Repository Status

✅ **All 11 projects are now synced with GitHub:**
- MOT_Check → citi94/MOT_Check
- bill_calculator → citi94/bill_calculator  
- bvm_98 → citi94/bvm_98 (renamed from bvmdeal_98)
- bvmdeal → citi94/bvmdeal
- charger_calculator → citi94/charger_calculator
- coffee_orders → citi94/coffee_orders
- evcompare → citi94/evcompare
- james → citi94/james
- mot_insert → citi94/mot_insert (with secure credential handling)
- order_coffee → citi94/order_coffee
- sync → citi94/sync (the sync system itself)

**Setup Complete:** All local folder names match GitHub repository names. The sync system is fully operational and ready for daily use across multiple computers.

**🚀 Bootstrap Ready:** The enhanced bootstrap system makes setting up new machines effortless with intelligent analysis and batch operations.

## Recommended Workflow

### 🚀 New Machine Setup
1. **Bootstrap sync system**:
   ```bash
   curl -L https://raw.githubusercontent.com/citi94/sync/main/bootstrap.sh | bash
   ```

2. **Analyze and sync**:
   ```bash
   cd /Users/peter/Projects && ./sync-projects.sh --bootstrap
   ```

### 📅 Daily Development
1. **Start of development session**:
   ```bash
   cd /Users/peter/Projects && ./sync-projects.sh --quick
   ```

2. **Work on your projects normally**

3. **End of development session** (optional):
   ```bash
   cd /Users/peter/Projects && ./sync-projects.sh --quick
   ```

## Troubleshooting

### Authentication Issues
```bash
gh auth login
gh auth status
```

### Merge Conflicts
If you encounter merge conflicts, the script will stop and you'll need to resolve them manually:
```bash
git status
git add .
git commit
./sync-projects.sh --quick
```

### View Logs
```bash
cat /Users/peter/Projects/sync.log
```

## Security Notes

- The script never forces pushes or overwrites remote changes
- Uncommitted changes are safely stashed and restored
- All operations are logged
- Interactive prompts for potentially destructive operations
- Public repositories are created by default (change in script if needed)

## Customization

To modify the script behavior:
- Edit `sync-projects.sh`
- Change `GITHUB_USERNAME` if needed
- Modify `PROJECTS_DIR` if your projects are elsewhere
- Adjust git ignore patterns as needed

## License

MIT License - Feel free to modify and distribute.