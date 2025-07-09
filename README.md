# Project Sync System

A simple bash script to keep all your coding projects synchronized between multiple computers and GitHub.

## Quick Start

```bash
# Daily sync (recommended)
./sync-projects.sh --quick

# Full interactive sync
./sync-projects.sh

# Check status of all repositories
./sync-projects.sh --status
```

## What It Does

- **Pulls** the latest changes from GitHub for all your projects
- **Pushes** any local commits you've made
- **Safely stashes** uncommitted changes before syncing
- **Restores** your uncommitted changes after syncing
- **Creates** GitHub repositories for new projects
- **Syncs itself** - the sync system is backed up to GitHub too!

## Safety Features

✅ **Won't lose your work** - automatically stashes uncommitted changes  
✅ **Won't break on errors** - continues with other projects if one fails  
✅ **Logs everything** - see what happened in `sync.log`  
✅ **Interactive prompts** - asks before creating new repositories  

## Requirements

- [GitHub CLI](https://cli.github.com/) installed and authenticated
- Git repositories with `origin` remotes pointing to GitHub

## File Structure

```
Projects/
├── sync/                    # The sync system itself
│   ├── sync-projects.sh     # Main script
│   ├── sync.log            # Operation log
│   ├── CLAUDE.md           # Detailed documentation
│   └── README.md           # This file
├── sync-projects.sh        # Wrapper script for easy access
├── your-project-1/         # Your actual projects
├── your-project-2/
└── ...
```

## How It Works

1. **Stash** any uncommitted changes in each project
2. **Fetch** and **pull** latest changes from GitHub
3. **Restore** your stashed changes
4. **Push** any local commits to GitHub
5. **Continue** to next project (even if one fails)

## Common Commands

```bash
# Quick daily sync
./sync-projects.sh --quick

# Full sync with prompts for new repos
./sync-projects.sh

# See what needs syncing
./sync-projects.sh --status

# Get help
./sync-projects.sh --help
```

## Troubleshooting

- **Authentication issues**: Run `gh auth login`
- **Merge conflicts**: Resolve manually, then run sync again
- **Missing remote**: The script will skip repositories without GitHub remotes
- **Check logs**: Look at `sync/sync.log` for detailed information

Perfect for developers who work on multiple machines and want to keep everything in sync! 🚀