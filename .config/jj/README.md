# Jujutsu (jj) Configuration

[Jujutsu](https://github.com/martinvonz/jj) is a Git-compatible version control system with a better user experience, automatic rebasing, and first-class conflict handling.

## Why Jujutsu?

| Feature | Git | Jujutsu |
|---------|-----|---------|
| Working copy | Must be tracked | Auto-snapshotted |
| Conflicts | Block workflow | First-class citizens |
| Rebasing | Manual, error-prone | Automatic |
| Undo | Limited (reflog) | Full operation log |
| Anonymous branches | No | Yes (working copy is always a commit) |
| Concurrent edits | Conflicts | Handles gracefully |

## Installation

```bash
# macOS
brew install jj

# Or via cargo
cargo install jj-cli
```

## Quick Start

### Initialize in Existing Git Repo

```bash
cd your-git-repo
jj git init --colocate
```

### Basic Workflow

```bash
# Check status
jj status
jj s                    # alias

# View log
jj log
jj l                    # alias (recent commits)
jj ll                   # alias (trunk to current)

# Make changes (auto-tracked!)
# Just edit files - jj tracks automatically

# Describe your changes
jj describe -m "feat: add new feature"
jj desc                 # alias

# Create new change (like git commit + checkout new branch)
jj new

# View diff
jj diff
jj d                    # alias

# Push to Git remote
jj git push
jj gp                   # alias
```

## Key Concepts

### Working Copy = Commit
In jj, your working copy IS a commit. Changes are automatically tracked.

### No Staging Area
No need for `git add`. All changes are part of the current commit.

### Automatic Rebasing
When you edit history, descendants are automatically rebased.

### Conflicts as First-Class Citizens
Conflicts don't block you. You can continue working and resolve later.

## Command Comparison

| Git | Jujutsu | Description |
|-----|---------|-------------|
| `git status` | `jj status` | View status |
| `git add . && git commit` | `jj describe` | Commit changes |
| `git checkout -b` | `jj new` | New change |
| `git log` | `jj log` | View history |
| `git diff` | `jj diff` | View changes |
| `git rebase -i` | `jj squash` / `jj split` | Edit history |
| `git stash` | Not needed | Working copy is always a commit |
| `git cherry-pick` | `jj duplicate` | Copy commits |

## Aliases Configured

```toml
s = status
l = log (recent)
ll = log (since trunk)
d = diff
ds = diff --summary
ci = commit
am = amend
sp = split
sq = squash
gf = git fetch
gp = git push
```

## Working with Git

jj is fully Git-compatible:

```bash
# Clone a Git repo
jj git clone https://github.com/user/repo

# Initialize in existing Git repo
jj git init --colocate

# Push to Git
jj git push

# Fetch from Git
jj git fetch
```

## Tips

### Edit Any Commit
```bash
jj edit @--      # Edit grandparent
jj edit abc123   # Edit specific commit
```

### Split a Commit
```bash
jj split         # Interactive split
```

### Squash Commits
```bash
jj squash        # Squash into parent
jj squash -r @-- # Squash specific commit
```

### Undo Anything
```bash
jj undo          # Undo last operation
jj op log        # View operation history
jj op restore 42 # Restore to operation 42
```

## Resources

- [Jujutsu Documentation](https://martinvonz.github.io/jj/)
- [Jujutsu Tutorial](https://martinvonz.github.io/jj/latest/tutorial/)
- [GitHub Repository](https://github.com/martinvonz/jj)
- [Steve Klabnik's jj Guide](https://steveklabnik.github.io/jujutsu-tutorial/)
