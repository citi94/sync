# Project Sync System Documentation

## Overview

This sync system ensures all your projects are synchronized between multiple computers and GitHub. It handles:
- Creating GitHub repositories for local projects
- Syncing existing repositories 
- Pulling latest changes from remote
- Pushing local changes to remote
- Managing uncommitted changes safely

## Files

- `sync-projects.sh` - Main GitHub sync script for project code
- `bootstrap.sh` - One-liner setup for new machines
- `sync.log` - Log file for all sync operations (gitignored)

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

## Claude Code Conversation Sync

Syncs `~/.claude/` (Claude Code conversations) automatically between machines using **Syncthing**.

**Primary machine:** `mac-mini` (always on, stores all conversations)

### Setup

**1. Install Syncthing on each machine:**
```bash
brew install syncthing
brew services start syncthing
```

**2. Access Web UI:** http://127.0.0.1:8384

**3. Add remote device:**
- Mac Mini Device ID: `RX4OYLQ-YZNAZ6V-5C3VTHZ-UTSYUJU-EWMAF5R-ITSXIDA-7VJMG7C-3DDCSQX`
- Click "Add Remote Device" and enter the device ID
- Accept the connection request on both machines

**4. Share the ~/.claude folder:**
- Click "Add Folder"
- Folder ID: `claude-sync`
- Folder Path: `/Users/[username]/.claude`
- Share with: select your other devices

### How It Works
- Syncthing runs as a background service
- Changes sync automatically within seconds
- Works over local network or internet (via relay if needed)
- End-to-end encrypted

### What Gets Synced
- `~/.claude/projects/` - All conversation transcripts
- `~/.claude/history.jsonl` - Session metadata
- `~/.claude/todos/` - Todo lists
- `~/.claude/settings.json` - Settings

### What Doesn't Get Synced
Add to `.stignore` in `~/.claude/`:
```
.credentials.json
statsig/
```

### Useful Commands
```bash
# Check Syncthing status
brew services list | grep syncthing

# Restart Syncthing
brew services restart syncthing

# View logs
tail -f ~/Library/Application\ Support/Syncthing/syncthing.log
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

## 🔄 iCloud Migration Plan for Sensitive Projects

### Overview

For macOS users with multiple machines, iCloud provides secure sync for sensitive projects (API keys, credentials, private tools) while keeping GitHub for public/deployable projects.

### Current Status (2025-07-18)

**✅ GitHub Synced Projects (15 total):**
- MOT_Check, bill_calculator, bvm_98, bvmapp, bvmdeal, coffee_orders, evcompare, order_coffee, sync, whisper, mot_insert, james, charger_calculator, catcounter, test_playground

**🔒 Candidates for iCloud Sync:**
- `starling/` - Banking integration with API keys and private keys
- Any future projects with sensitive credentials
- Development tools and scripts
- Local configuration files

### Migration Strategy

#### Phase 1: Preparation (BEFORE moving files)

**On Current Machine (Machine A):**
1. **Document sensitive files** in each project:
   ```bash
   find starling/ -name "*key*" -o -name "*api*" -o -name "*secret*" -o -name "*token*"
   ```

2. **Create backup inventory:**
   ```bash
   ls -la starling/ > ~/Desktop/starling_inventory_machineA.txt
   ```

3. **Check for uncommitted changes:**
   ```bash
   # From Projects directory
   for dir in */; do 
     if [ -d "$dir/.git" ]; then 
       echo "=== $dir ==="; 
       cd "$dir" && git status --porcelain && cd ..; 
     fi; 
   done
   ```

#### Phase 2: iCloud Setup

**Create iCloud Structure:**
```
~/Library/Mobile Documents/com~apple~CloudDocs/
├── Development/
│   ├── Private-Projects/
│   │   └── starling/           # Full project with credentials
│   ├── Config/
│   │   ├── ssh-keys/
│   │   └── api-credentials/
│   └── Scripts/
│       └── automation-tools/
└── Sync-Staging/               # Temporary staging area
```

#### Phase 3: Migration Process

**Step 1: Create iCloud Development Folder**
```bash
mkdir -p ~/Library/Mobile\ Documents/com~apple~CloudDocs/Development/Private-Projects
mkdir -p ~/Library/Mobile\ Documents/com~apple~CloudDocs/Development/Sync-Staging
```

**Step 2: Move Sensitive Projects to Staging**
```bash
# Copy (don't move yet) to staging
cp -r ~/Projects/starling ~/Library/Mobile\ Documents/com~apple~CloudDocs/Development/Sync-Staging/
```

**Step 3: Wait for iCloud Sync (CRITICAL)**
- **Wait 10-15 minutes** for iCloud to fully sync
- **Verify on iPhone/iPad** that files appear in Files app
- **Check file sizes** match original

**Step 4: Verify on Other Machine (Machine B)**
1. **Check iCloud sync status:**
   ```bash
   ls -la ~/Library/Mobile\ Documents/com~apple~CloudDocs/Development/Sync-Staging/
   ```

2. **Compare inventories:**
   ```bash
   ls -la ~/Library/Mobile\ Documents/com~apple~CloudDocs/Development/Sync-Staging/starling/ > ~/Desktop/starling_inventory_machineB.txt
   diff ~/Desktop/starling_inventory_machineA.txt ~/Desktop/starling_inventory_machineB.txt
   ```

**Step 5: Final Migration (Only after verification)**
```bash
# On both machines, move from staging to final location
mv ~/Library/Mobile\ Documents/com~apple~CloudDocs/Development/Sync-Staging/starling ~/Library/Mobile\ Documents/com~apple~CloudDocs/Development/Private-Projects/

# Remove from Projects directory (keep backup first!)
mv ~/Projects/starling ~/Projects/starling.backup.$(date +%Y%m%d)
```

#### Phase 4: Create Symlinks (Optional)

**For convenience, create symlinks in Projects directory:**
```bash
ln -s ~/Library/Mobile\ Documents/com~apple~CloudDocs/Development/Private-Projects/starling ~/Projects/starling
```

### Conflict Resolution Strategy

#### If Duplicates Exist on Both Machines:

**Scenario A: Different Files**
1. **Rename both versions:**
   ```bash
   mv starling starling-machineA
   mv starling starling-machineB
   ```

2. **Manual merge:**
   - Compare file-by-file
   - Use newer API keys (check creation dates)
   - Merge any code changes manually

**Scenario B: Same Project, Different States**
1. **Use git to help (if initialized):**
   ```bash
   cd starling-machineA && git status
   cd starling-machineB && git status
   ```

2. **Merge strategy:**
   - Keep the version with more recent commits
   - Copy any machine-specific config files
   - Update credentials to latest versions

### Safety Measures

**Before Any Migration:**
1. **Time Machine backup** both machines
2. **Manual backup** to external drive:
   ```bash
   cp -r ~/Projects ~/Desktop/Projects-Backup-$(date +%Y%m%d)
   ```

**During Migration:**
1. **Never delete originals** until verified on both machines
2. **Test iCloud sync** with a small test file first
3. **Document everything** in staging notes

**After Migration:**
1. **Test applications** work from new locations
2. **Update any hardcoded paths** in scripts
3. **Verify credentials** still work

### Emergency Rollback Plan

**If iCloud Migration Fails:**
1. **Stop sync system:**
   ```bash
   # Disable iCloud sync temporarily
   ```

2. **Restore from backup:**
   ```bash
   cp -r ~/Desktop/Projects-Backup-YYYYMMDD/* ~/Projects/
   ```

3. **Resume GitHub sync:**
   ```bash
   cd ~/Projects/sync && ./sync-projects.sh --status
   ```

### Post-Migration Benefits

**Security:**
- ✅ API keys never touch GitHub
- ✅ End-to-end encryption via iCloud
- ✅ Automatic backup to Apple servers

**Convenience:**
- ✅ Instant sync across all Apple devices
- ✅ Access from iPhone/iPad for reference
- ✅ No manual git operations needed

**Organization:**
- ✅ Clear separation of public vs private projects
- ✅ GitHub for collaboration/deployment
- ✅ iCloud for personal/sensitive tools

### Recommended Timeline

**Day 1:** Preparation and backup
**Day 2:** Create iCloud structure and test sync
**Day 3:** Migration and verification  
**Day 4:** Testing and optimization

**⚠️ Critical Success Factors:**
1. **Never rush** - iCloud sync takes time
2. **Always verify** before deleting originals  
3. **Test thoroughly** after migration
4. **Keep backups** until 100% confident

## License

MIT License - Feel free to modify and distribute.