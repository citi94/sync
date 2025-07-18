# Bootstrap Workflow for New Machines

## Phase 1: Get the Sync System

**One-liner to bootstrap sync system:**
```bash
# Option A: Direct clone
git clone https://github.com/citi94/sync.git ~/Desktop/sync-temp && cp -r ~/Desktop/sync-temp/* ~/Projects/sync/ && rm -rf ~/Desktop/sync-temp

# Option B: wget/curl approach
curl -L https://github.com/citi94/sync/archive/main.zip -o sync.zip && unzip sync.zip && mv sync-main/* ~/Projects/sync/
```

## Phase 2: Analysis & Planning

**Enhanced sync script with bootstrap mode:**
```bash
./sync-projects.sh --bootstrap
```

This would:
1. **Scan** existing local projects vs GitHub repos
2. **Present** a table showing what would happen:
   ```
   Project Status Analysis:
   ┌─────────────────┬──────────────┬────────────────┬─────────────────┐
   │ Project         │ Local Status │ GitHub Status  │ Proposed Action │
   ├─────────────────┼──────────────┼────────────────┼─────────────────┤
   │ project1        │ Git repo     │ Exists         │ Sync            │
   │ project2        │ No git       │ Exists         │ Clone (backup)  │
   │ project3        │ Git repo     │ Missing        │ Create GitHub   │
   │ project4        │ Missing      │ Exists         │ Clone           │
   │ project5        │ No git       │ Missing        │ Create both     │
   └─────────────────┴──────────────┴────────────────┴─────────────────┘
   ```

3. **Batch Options**:
   - `a` - Accept all proposed actions
   - `s` - Selective mode (choose individually)
   - `c` - Clone only (don't create new repos)
   - `q` - Quit without changes

## Phase 3: Conflict Resolution

**For Git history conflicts:**
- Create backup branch before merge
- Offer options: merge, rebase, or manual resolution
- Show diff summary before proceeding

## Phase 4: Machine-Specific Configuration

**Path Configuration:**
```bash
# Allow different project directories
./sync-projects.sh --configure
# Sets PROJECTS_DIR in script or config file
```

**Selective Project Lists:**
```bash
# Create .syncignore file for projects to skip
echo "old-project" >> .syncignore
echo "experimental-*" >> .syncignore
```

## Bootstrap Command Examples

**Complete new machine setup:**
```bash
# 1. Bootstrap sync system
curl -L https://github.com/citi94/sync/archive/main.zip -o sync.zip && unzip sync.zip

# 2. Set up Projects directory
mkdir -p ~/Projects/sync
mv sync-main/* ~/Projects/sync/
cd ~/Projects

# 3. Configure for this machine
./sync-projects.sh --configure

# 4. Run bootstrap analysis
./sync-projects.sh --bootstrap

# 5. Execute sync plan
./sync-projects.sh --bootstrap --execute
```

**Existing machine with some projects:**
```bash
# 1. Get sync system (if not present)
cd ~/Projects && git clone https://github.com/citi94/sync.git

# 2. Analyze current state
./sync-projects.sh --bootstrap

# 3. Execute selective sync
./sync-projects.sh --bootstrap --selective
```

## Safety Features

- **Backup creation** before any destructive operations
- **Dry run mode** to preview changes
- **Rollback capability** if something goes wrong
- **Detailed logging** of all operations