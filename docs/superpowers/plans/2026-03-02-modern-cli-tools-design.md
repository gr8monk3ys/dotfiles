# Modern CLI Tools Expansion — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add 16 high-value CLI tools across Git/DevOps, data, system, and productivity categories, add lazygit aliases, and fix the untracked git ignore file.

**Architecture:** All tools are added to `install/Brewfile` (one new tap for gh-dash). Shell aliases are added to `.config/zsh/aliases.zsh` following existing conventions (command -v guards, don't shadow builtins, grouped by category). No new config directories needed.

**Tech Stack:** Homebrew (package install), Zsh (aliases)

---

## Tasks

### Task 1: Fix untracked .config/git/ignore

**Files:**

- Commit: `.config/git/ignore` (already exists, just untracked)

**Step 1: Stage and commit the git ignore file**

```bash
git add .config/git/ignore
git commit -m "chore: track global gitignore for claude settings"
```

---

### Task 2: Add new tap and tools to Brewfile

**Files:**

- Modify: `install/Brewfile`

**Step 1: Add gh-dash tap after line 18 (vldmrkl tap)**

After `tap "vldmrkl/formulae"`, add:

```
tap "dlvhdr/gh-dash"                   # GitHub dashboard extension
```

**Step 2: Add lazydocker and gh-dash to Git/DevOps section**

After line 51 (`brew "lazygit"`), add:

```
brew "lazydocker"                      # Terminal UI for Docker
brew "dlvhdr/gh-dash/gh-dash"          # GitHub dashboard TUI
```

**Step 3: Add jq to File & Text Search section**

After line 123 (`brew "sk"`), add:

```
brew "jq"                              # JSON processor
```

**Step 4: Add new tools in a new section before Shell History**

After the "Next-Gen Modern Tools (2024+)" section (after line 153, `brew "ouch"`), add a new section:

```
# ============================================================================
# Modern CLI Tools (2025+ additions)
# ============================================================================

## Data & JSON
brew "jnv"                             # Interactive JSON navigator with jq
brew "glow"                            # Terminal markdown renderer
brew "csvlens"                         # Interactive CSV viewer
brew "xsv"                             # Fast CSV toolkit (Rust)

## System & Network
brew "duf"                             # Modern df replacement (disk free)
brew "doggo"                           # Modern DNS client (replaces dig)
brew "bandwhich"                       # Network utilization by process
brew "viddy"                           # Modern watch command with diffs
brew "trippy"                          # Network diagnostic TUI (mtr/traceroute)

## Developer Productivity
brew "just"                            # Command runner (simpler make)
brew "difftastic"                      # Structural/syntax-aware diffs
brew "grex"                            # Generate regex from examples
brew "topgrade"                        # Universal system updater
```

**Step 5: Commit**

```bash
git add install/Brewfile
git commit -m "feat: add 16 modern CLI tools to Brewfile

Add tools across four categories:
- Git/DevOps: lazydocker, gh-dash
- Data/JSON: jq, jnv, glow, csvlens, xsv
- System/Network: duf, doggo, bandwhich, viddy, trippy
- Productivity: just, difftastic, grex, topgrade"
```

---

### Task 3: Add lazygit and new tool aliases to aliases.zsh

**Files:**

- Modify: `.config/zsh/aliases.zsh`

**Step 1: Add lazygit aliases**

After the Ouch section (after line 306, the `fi` closing the ouch block), add before the Utility Aliases section header:

```zsh
# lazygit - Terminal UI for git
if command -v lazygit &> /dev/null; then
    alias lg='lazygit'
    alias lgd='lazygit -p .'  # current directory
fi

# lazydocker - Terminal UI for Docker
if command -v lazydocker &> /dev/null; then
    alias lzd='lazydocker'
fi
```

**Step 2: Add data & JSON tool aliases**

Continue adding after the lazydocker block:

```zsh
# jq (use jq directly — it's already the standard)

# jnv - Interactive JSON navigator
if command -v jnv &> /dev/null; then
    alias jqi='jnv'  # interactive jq
fi

# glow - Terminal markdown renderer
if command -v glow &> /dev/null; then
    alias md='glow'  # render markdown
    alias mdp='glow -p'  # render with pager
fi

# csvlens - Interactive CSV viewer
if command -v csvlens &> /dev/null; then
    alias csv='csvlens'
fi
```

**Step 3: Add system & network tool aliases**

```zsh
# duf - Modern df replacement (use duf directly, don't shadow df)
# df is used in scripts — duf output is not parseable the same way

# doggo - Modern DNS client (use doggo directly, don't shadow dig)
# dig is scripted everywhere — doggo has different output format

# bandwhich - Network utilization (needs sudo)
if command -v bandwhich &> /dev/null; then
    alias bw='sudo bandwhich'
fi

# viddy - Modern watch command
if command -v viddy &> /dev/null; then
    alias watch='viddy'
    alias watchd='viddy -d'  # with diff highlighting
fi

# trippy - Network diagnostic TUI
if command -v trip &> /dev/null; then
    alias mtr='sudo trip'  # trippy replaces mtr
fi
```

**Step 4: Add developer productivity aliases**

```zsh
# just - Command runner (use just directly, don't shadow make)
# just has its own completions and workflow

# difftastic (configured via GIT_EXTERNAL_DIFF or git config)
if command -v difft &> /dev/null; then
    alias difft='difft'  # explicit alias for discoverability
    alias gdd='git -c diff.external=difft diff'  # git diff with difftastic
fi

# grex - Regex generator (use grex directly)

# topgrade - Universal system updater
if command -v topgrade &> /dev/null; then
    alias tg='topgrade'
    alias tgn='topgrade -n'  # dry run
fi
```

**Step 5: Commit**

```bash
git add .config/zsh/aliases.zsh
git commit -m "feat: add aliases for lazygit, lazydocker, and 16 new CLI tools

Aliases follow existing conventions:
- command -v guards for optional tools
- Don't shadow builtins used in scripts (df, dig, make)
- Short mnemonics (lg, lzd, tg, md, csv, bw)"
```

---

### Task 4: Install the new packages

**Step 1: Run brew bundle to install everything**

```bash
brew bundle --file=install/Brewfile
```

Expected: All 16 new tools install successfully (some may already be installed).

---
